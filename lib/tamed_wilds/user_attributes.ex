defmodule TamedWilds.UserAttributes do
  use Ecto.Schema
  import Ecto.Query

  alias __MODULE__
  alias TamedWilds.Accounts.User
  alias TamedWilds.Repo
  alias TamedWilds.Creatures.Creature
  alias TamedWilds.UserAttributes.UserLevel

  schema "user_attributes" do
    field :current_energy, :integer
    field :max_energy, :integer

    field :current_health, :integer
    field :max_health, :integer

    field :inventory_size, :integer

    field :experience, :integer
    field :level, :integer

    belongs_to :companion, TamedWilds.Creatures.Creature

    belongs_to :user, User
  end

  def initial_setup(%User{} = user) do
    Repo.insert!(%UserAttributes{user_id: user.id})
  end

  def get!(%User{} = user) do
    by_user(user) |> with_companion() |> Repo.one!()
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

  def regenerate_energy_of_all_users(by) do
    query =
      from u in UserAttributes,
        where: u.current_energy < u.max_energy,
        update: [
          set: [current_energy: fragment("least(?, ?)", u.current_energy + ^by, u.max_energy)]
        ]

    Repo.update_all(query, [])
  end

  def regenerate_health_of_all_users(by) do
    query =
      from u in UserAttributes,
        where: u.current_health < u.max_health,
        update: [
          set: [current_health: fragment("least(?, ?)", u.current_health + ^by, u.max_health)]
        ]

    Repo.update_all(query, [])
  end
end
