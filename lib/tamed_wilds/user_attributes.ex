defmodule TamedWilds.UserAttributes do
  use Ecto.Schema
  import Ecto.Query

  alias __MODULE__
  alias TamedWilds.Accounts.User
  alias TamedWilds.Repo
  alias TamedWilds.Creatures.Creature
  alias TamedWilds.UserAttributes.UserLevel

  @attributes [:health, :energy, :damage, :resistance]
  @max_health_increase_per_health_point 10
  @max_energy_increase_per_energy_point 10
  @damage_percentage_increase_per_damage_point 5

  @base_max_health 100
  @base_max_energy 100

  schema "user_attributes" do
    field :current_energy, :integer
    field :max_energy, :integer

    field :current_health, :integer
    field :max_health, :integer

    field :inventory_size, :integer

    field :experience, :integer
    field :level, :integer

    field :health_points, :integer
    field :energy_points, :integer
    field :damage_points, :integer
    field :resistance_points, :integer

    belongs_to :companion, TamedWilds.Creatures.Creature

    belongs_to :user, User
  end

  def initial_setup(%User{} = user) do
    Repo.insert!(%UserAttributes{user_id: user.id})
  end

  def get!(%User{} = user) do
    by_user(user) |> with_companion() |> Repo.one!()
  end

  def by_id(id) do
    from ua in UserAttributes, where: ua.id == ^id
  end

  def by_user(%User{} = user) do
    from ua in UserAttributes, where: ua.user_id == ^user.id
  end

  def with_companion(%Ecto.Query{} = query) do
    from ua in query,
      left_join: c in assoc(ua, :companion),
      as: :companion,
      preload: [companion: c]
  end

  def reduce_energy(%User{} = user, amount) do
    query =
      from u in UserAttributes,
        where: u.user_id == ^user.id and u.current_energy >= ^amount

    case Repo.update_all(query, inc: [current_energy: -amount]) do
      {0, _} -> {:error, :not_enough_energy}
      _ -> :ok
    end
  end

  def do_damage(%User{} = user, amount) do
    query =
      from u in UserAttributes,
        where: u.user_id == ^user.id,
        update: [set: [current_health: fragment("greatest(?, ?)", u.current_health - ^amount, 0)]],
        select: u

    case Repo.update_all(query, []) do
      {1, [%UserAttributes{current_health: 0}]} -> {:ok, :dead}
      {1, _} -> {:ok, :alive}
    end
  end

  @doc """
  Adds experience to the player.

  Should be called in a transaction.
  """
  def add_experience(%User{} = user, amount) do
    query =
      from u in UserAttributes,
        where: u.user_id == ^user.id,
        update: [inc: [experience: ^amount]],
        select: u

    {1, [%UserAttributes{level: previous_level, experience: new_experience}]} =
      Repo.update_all(query, [])

    new_level = UserLevel.get_new_level(previous_level, new_experience)

    if new_level > previous_level do
      query =
        from u in UserAttributes,
          where: u.user_id == ^user.id,
          update: [set: [level: ^new_level]],
          select: u

      {1, _} = Repo.update_all(query, [])
    end

    :ok
  end

  def get_companion(%User{} = user) do
    query =
      from ua in by_user(user),
        left_join: c in assoc(ua, :companion),
        select: c

    Repo.one(query)
  end

  def min_hp_percentage_for_set_companion, do: 20

  def clear_companion(%User{} = user) do
    {1, _} = Repo.update_all(by_user(user), set: [companion_id: nil])

    :ok
  end

  def set_companion(%User{} = user, creature_id) do
    case Repo.get(Creature, creature_id) do
      nil ->
        {:error, :creature_not_found}

      creature ->
        cond do
          creature.tamed_by != user.id ->
            {:error, :not_tamed_by_user}

          creature.current_health <
              creature.max_health * min_hp_percentage_for_set_companion() / 100 ->
            {:error, :companion_too_low_health}

          true ->
            {1, _} = Repo.update_all(by_user(user), set: [companion_id: creature_id])

            :ok
        end
    end
  end

  def do_damage_to_companion(%User{} = user, %Creature{} = companion, damage) do
    {1, [%Creature{current_health: new_companion_health}]} =
      Creature.by_id(companion.id)
      |> Creature.with_do_damage(damage)
      |> Repo.update_all([])

    if new_companion_health <= 0 do
      :ok = UserAttributes.clear_companion(user)
      {:ok, :defeated}
    else
      {:ok, :alive}
    end
  end

  def unspent_points(%UserAttributes{} = user_attributes) do
    total_points = user_attributes.level - 1

    unspent_points =
      total_points -
        user_attributes.health_points -
        user_attributes.energy_points -
        user_attributes.damage_points -
        user_attributes.resistance_points

    unspent_points
  end

  def filter_has_unspent_points(%Ecto.Query{} = query) do
    from ua in query,
      where:
        ua.level - ^1 - ua.health_points - ua.energy_points - ua.damage_points -
          ua.resistance_points > 0
  end

  def spend_attribute_point(%User{} = user, attribute)
      when attribute in @attributes do
    query = by_user(user) |> filter_has_unspent_points()

    case Repo.update_all(query, spend_attribute_point_update(attribute)) do
      {0, _} -> {:error, :not_enough_points}
      _ -> :ok
    end
  end

  defp spend_attribute_point_update(attribute) when attribute in @attributes do
    case attribute do
      :health -> [inc: [health_points: 1, max_health: @max_health_increase_per_health_point]]
      :energy -> [inc: [energy_points: 1, max_energy: @max_energy_increase_per_energy_point]]
      :damage -> [inc: [damage_points: 1]]
      :resistance -> [inc: [resistance_points: 1]]
    end
  end

  def reset_attribute_points(%User{} = user) do
    query =
      from ua in by_user(user),
        update: [
          set: [
            health_points: 0,
            energy_points: 0,
            damage_points: 0,
            resistance_points: 0,
            max_health: @base_max_health,
            max_energy: @base_max_energy,
            current_health: fragment("least(?, ?)", ua.current_health, @base_max_health),
            current_energy: fragment("least(?, ?)", ua.current_energy, @base_max_energy)
          ]
        ]

    {1, _} = Repo.update_all(query, [])
    :ok
  end

  def outgoing_damage_percentage(%UserAttributes{} = user_attributes) do
    100 + user_attributes.damage_points * @damage_percentage_increase_per_damage_point
  end

  def incoming_damage_percentage(%UserAttributes{} = user_attributes) do
    if user_attributes.resistance_points == 0 do
      100
    else
      :math.pow(0.98, :math.log(user_attributes.resistance_points) / :math.log(1.5)) * 100
    end
  end

  def regenerate_energy_of_all_users(by_percentage) do
    query =
      from u in UserAttributes,
        where: u.current_energy < u.max_energy,
        update: [
          set: [
            current_energy:
              fragment(
                "least(?, ?)",
                u.current_energy + u.max_energy * ^by_percentage / 100.0,
                u.max_energy
              )
          ]
        ]

    Repo.update_all(query, [])
  end

  def regenerate_health_of_all_users(by_percentage) do
    query =
      from u in UserAttributes,
        where: u.current_health < u.max_health,
        update: [
          set: [
            current_health:
              fragment(
                "least(?, ?)",
                u.current_health + u.max_health * ^by_percentage / 100.0,
                u.max_health
              )
          ]
        ]

    Repo.update_all(query, [])
  end
end
