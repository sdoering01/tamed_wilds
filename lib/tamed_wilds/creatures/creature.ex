defmodule TamedWilds.Creatures.Creature do
  use Ecto.Schema
  import Ecto.Query
  import Ecto.Changeset

  alias __MODULE__
  alias TamedWilds.Accounts.User

  schema "creatures" do
    field :res_id, :integer
    field :current_health, :integer
    field :max_health, :integer

    field :experience, :integer
    field :level, :integer
    field :level_after_tamed, :integer

    field :tamed_at, :utc_datetime_usec

    belongs_to :user, User, foreign_key: :tamed_by
  end

  def by_id(id) do
    from c in Creature, where: c.id == ^id
  end

  def tamed_by_user(%User{} = user) do
    from c in Creature, where: c.tamed_by == ^user.id
  end

  def delete_by_id_query(id) do
    from c in by_id(id), select: c
  end

  def tame_changeset(%Creature{} = creature, %User{} = user, tamed_at) do
    creature |> change(tamed_by: user.id, tamed_at: tamed_at, level_after_tamed: creature.level)
  end

  def with_do_damage(%Ecto.Query{} = query, damage) do
    from c in query,
      update: [
        set: [
          current_health: fragment("greatest(?, ?)", c.current_health - ^damage, 0)
        ]
      ],
      select: c
  end
end
