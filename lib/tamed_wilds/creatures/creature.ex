defmodule TamedWilds.Creatures.Creature do
  use Ecto.Schema
  import Ecto.Query
  import Ecto.Changeset

  alias __MODULE__
  alias TamedWilds.Accounts.User

  @damage_factor_increase_per_damage_point_untamed 0.05
  @damage_factor_increase_per_damage_point_tamed 0.02

  @health_factor_increase_per_health_point_untamed 0.20
  @health_factor_increase_per_health_point_tamed 0.05

  schema "creatures" do
    field :res_id, :integer
    field :current_health, :integer
    field :max_health, :integer

    field :experience, :integer
    field :level, :integer
    field :level_after_tamed, :integer

    field :health_points, :integer
    field :energy_points, :integer
    field :damage_points, :integer
    field :resistance_points, :integer

    # Attribute points right after taming
    field :health_points_after_tamed, :integer
    field :energy_points_after_tamed, :integer
    field :damage_points_after_tamed, :integer
    field :resistance_points_after_tamed, :integer

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
      level_after_tamed: creature.level,
      health_points_after_tamed: creature.health_points,
      energy_points_after_tamed: creature.energy_points,
      damage_points_after_tamed: creature.damage_points,
      resistance_points_after_tamed: creature.resistance_points
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
    if is_nil(creature.tamed_by) do
      1 + creature.damage_points * @damage_factor_increase_per_damage_point_untamed
    else
      user_skilled_points = creature.damage_points - creature.damage_points_after_tamed

      factor_after_tamed =
        1 + creature.damage_points_after_tamed * @damage_factor_increase_per_damage_point_untamed

      factor_skilled = 1 + user_skilled_points * @damage_factor_increase_per_damage_point_tamed

      # Gives a bonus for tamed creatures that are skilled
      factor_after_tamed * factor_skilled
    end
  end

  def incoming_damage_factor(%Creature{} = creature) do
    if creature.resistance_points == 0 do
      1
    else
      if is_nil(creature.tamed_by) do
        :math.pow(0.98, :math.log(creature.resistance_points) / :math.log(1.5))
      else
        user_skilled_points = creature.resistance_points - creature.resistance_points_after_tamed

        factor_after_tamed =
          :math.pow(0.98, :math.log(creature.resistance_points_after_tamed) / :math.log(1.5))

        factor_skilled =
          :math.pow(0.98, :math.log(user_skilled_points) / :math.log(1.5))

        # Gives a bonus for tamed creatures that are skilled
        factor_after_tamed * factor_skilled
      end
    end
  end

  def health_factor_increase_per_health_point_untamed,
    do: @health_factor_increase_per_health_point_untamed
end
