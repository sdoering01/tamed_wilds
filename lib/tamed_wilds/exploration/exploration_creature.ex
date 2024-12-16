defmodule TamedWilds.Exploration.ExplorationCreature do
  use Ecto.Schema
  import Ecto.Query

  alias __MODULE__
  alias TamedWilds.Accounts.User

  schema "exploration_creatures" do
    field :creature_id, :integer
    field :health, :integer
    field :max_health, :integer

    belongs_to :user, User
  end

  def by_user(%User{} = user) do
    from ec in ExplorationCreature, where: ec.user_id == ^user.id
  end

  def filter_defeated(%Ecto.Query{} = query) do
    from ec in query, where: ec.health <= 0
  end

  def do_damage(%Ecto.Query{} = query, damage) do
    from ec in query, update: [set: [health: fragment("greatest(?, ?)", ec.health - ^damage, 0)]]
  end
end
