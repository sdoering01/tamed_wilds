defmodule TamedWilds.Creatures.Creature do
  use Ecto.Schema
  import Ecto.Query
  import Ecto.Changeset

  alias __MODULE__
  alias TamedWilds.Accounts.User
  alias TamedWilds.GameResources, as: Res

  @damage_factor_increase_per_damage_point_wild 0.05
  @damage_factor_increase_per_damage_point_tamed 0.02

  @health_factor_increase_per_health_point_wild 0.20
  @health_factor_increase_per_health_point_tamed 0.05

  schema "creatures" do
    field :res_id, :integer
    field :current_health, :integer
    field :max_health, :integer

    field :experience, :integer
    field :level, :integer
    field :level_after_tamed, :integer

    field :health_points_wild, :integer
    field :energy_points_wild, :integer
    field :damage_points_wild, :integer
    field :resistance_points_wild, :integer

    # Attribute points right after taming
    field :health_points_tamed, :integer
    field :energy_points_tamed, :integer
    field :damage_points_tamed, :integer
    field :resistance_points_tamed, :integer

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
    creature
    |> change(
      tamed_by: user.id,
      tamed_at: tamed_at,
      level_after_tamed: creature.level
    )
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

  def outgoing_damage_factor(%Creature{} = creature) do
    factor_wild =
      1 + creature.damage_points_wild * @damage_factor_increase_per_damage_point_wild

    factor_tamed =
      1 + creature.damage_points_tamed * @damage_factor_increase_per_damage_point_tamed

    # Gives a bonus for tamed creatures that are skilled
    factor_wild * factor_tamed
  end

  def incoming_damage_factor(%Creature{} = creature) do
    factor_wild = :math.pow(0.98, :math.log(creature.damage_points_wild + 1) / :math.log(1.5))
    factor_tamed = :math.pow(0.98, :math.log(creature.damage_points_tamed + 1) / :math.log(1.5))

    # Gives a bonus for tamed creatures that are skilled
    factor_wild * factor_tamed
  end

  def max_health_from_attributes(
        %Res.Creature{} = creature_res,
        health_points_wild,
        health_points_tamed
      ) do
    factor_wild = 1 + health_points_wild * @health_factor_increase_per_health_point_wild

    factor_tamed = 1 + health_points_tamed * @health_factor_increase_per_health_point_tamed

    # Gives a bonus for tamed creatures that are skilled
    round(factor_wild * factor_tamed * creature_res.base_max_health)
  end
end
