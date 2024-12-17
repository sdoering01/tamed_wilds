defmodule TamedWilds.UserAttributes do
  use Ecto.Schema
  import Ecto.Query

  alias __MODULE__
  alias TamedWilds.Accounts.User
  alias TamedWilds.Repo
  alias TamedWilds.GameResources, as: Res

  @primary_key false
  schema "user_attributes" do
    field :current_energy, :integer
    field :max_energy, :integer

    field :current_health, :integer
    field :max_health, :integer

    field :inventory_size, :integer

    field :experience, :integer
    field :level, :integer

    belongs_to :user, TamedWilds.Accounts.User
  end

  def initial_setup(%User{} = user) do
    Repo.insert!(%UserAttributes{user_id: user.id})
  end

  def get!(%User{} = user) do
    Repo.get_by!(UserAttributes, user_id: user.id)
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

    new_level = Res.UserLevel.get_new_level(previous_level, new_experience)

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
