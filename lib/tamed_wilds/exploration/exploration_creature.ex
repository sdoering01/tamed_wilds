defmodule TamedWilds.Exploration.ExplorationCreature do
  use Ecto.Schema
  import Ecto.Query

  alias __MODULE__
  alias TamedWilds.Accounts.User
  alias TamedWilds.Creatures.Creature

  schema "exploration_creatures" do
    belongs_to :creature, Creature
    belongs_to :user, User
  end

  def by_user(%User{} = user) do
    from ec in ExplorationCreature, where: ec.user_id == ^user.id
  end

  def with_creature(%Ecto.Query{} = query) do
    from ec in query,
      join: c in assoc(ec, :creature),
      as: :creature,
      preload: [creature: c]
  end

  def filter_defeated(%Ecto.Query{} = query) do
    from [creature: c] in query, where: c.current_health <= 0
  end

  def delete_defeated_query(%User{} = user) do
    by_user(user) |> with_creature() |> filter_defeated() |> exclude(:preload) |> select([ec], ec)
  end

  def associated_creature_query(%User{} = user) do
    from c in Creature,
      join: ec in subquery(by_user(user)),
      on: c.id == ec.creature_id
  end

  def do_damage_query(%User{} = user, damage) do
    user |> associated_creature_query() |> Creature.with_do_damage(damage)
  end
end
