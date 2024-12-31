defmodule TamedWilds.Creatures.Creature do
  use Ecto.Schema
  import Ecto.Query
  import Ecto.Changeset

  alias __MODULE__
  alias TamedWilds.Accounts.User
  alias TamedWilds.GameResources, as: Res

  @attributes [:health, :energy, :damage, :resistance]

  @damage_factor_increase_per_damage_point_wild 0.05
  @damage_factor_increase_per_damage_point_tamed 0.02

  @health_factor_increase_per_health_point_wild 0.20
  @health_factor_increase_per_health_point_tamed 0.05

  @food_value_to_tame_factor_increase_per_level 0.08

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

  def food_value_to_tame(%Res.Creature{} = creature_res, level) do
    factor = 1 + @food_value_to_tame_factor_increase_per_level * (level - 1)

    round(creature_res.taming.base_food_value_to_tame * factor)
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

  def unspent_points(%Creature{} = creature) do
    total_points_tamed = creature.level - creature.level_after_tamed

    unspent_points =
      total_points_tamed -
        creature.health_points_tamed -
        creature.energy_points_tamed -
        creature.damage_points_tamed -
        creature.resistance_points_tamed

    unspent_points
  end

  def filter_has_unspent_points(%Ecto.Query{} = query) do
    from c in query,
      where:
        c.level - c.level_after_tamed - c.health_points_tamed - c.energy_points_tamed -
          c.damage_points_tamed - c.resistance_points_tamed > 0
  end

  def spend_attribute_point_update(%Creature{} = creature, attribute)
      when attribute in @attributes do
    case attribute do
      :health ->
        creature_res = Res.Creature.get_by_res_id(creature.res_id)

        new_health_points_tamed = creature.health_points_tamed + 1

        new_max_health =
          max_health_from_attributes(
            creature_res,
            creature.health_points_wild,
            new_health_points_tamed
          )

        # Using `set` instead of `inc` so that concurrent requests don't
        # cannot increase the points two times but set the max health to the
        # same new value.
        #
        # This way, the two concurrent queries would have the same effect. But
        # unspent points are based on the amount of spent points anyways, so
        # that this is fine.
        [
          set: [
            health_points_tamed: new_health_points_tamed,
            max_health: new_max_health
          ]
        ]

      :energy ->
        [inc: [energy_points_tamed: 1]]

      :damage ->
        [inc: [damage_points_tamed: 1]]

      :resistance ->
        [inc: [resistance_points_tamed: 1]]
    end
  end

  def attributes(), do: @attributes
end
