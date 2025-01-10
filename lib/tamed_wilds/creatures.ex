defmodule TamedWilds.Creatures do
  import Ecto.Query

  alias TamedWilds.Accounts.User
  alias TamedWilds.Creatures.{Creature, CreatureLevel}
  alias TamedWilds.Repo
  alias TamedWilds.Exploration.Taming
  alias TamedWilds.GameResources, as: Res

  @attributes Creature.attributes()

  def get_user_creatures(%User{} = user) do
    Creature.tamed_by_user(user) |> Repo.all()
  end

  def tame_creature(%User{} = user, %Creature{} = creature, tamed_at, taming_effectiveness) do
    level_gain = Taming.level_gain(creature.level, taming_effectiveness)
    attribute_increases = roll_attributes(level_gain)
    new_level = creature.level + level_gain

    creature
    |> Creature.tame_changeset(
      user,
      tamed_at,
      new_level,
      attribute_increases,
      taming_effectiveness
    )
    |> Repo.update()
  end

  def regenerate_health_of_tamed_creatures(by_factor) do
    query =
      from c in Creature,
        where: not is_nil(c.tamed_by),
        where: c.current_health < c.max_health,
        update: [
          set: [
            current_health:
              fragment(
                "least(ceil(?), ?)",
                # 1.0 to make adapter understand that `by_factor` is a float
                c.current_health + 1.0 * c.max_health * ^by_factor,
                c.max_health
              )
          ]
        ]

    Repo.update_all(query, [])
  end

  def add_experience(%Creature{} = creature, experience) do
    query =
      from c in Creature,
        where: c.id == ^creature.id,
        update: [inc: [experience: ^experience]],
        select: c

    {1, [%Creature{experience: new_experience}]} = Repo.update_all(query, [])

    new_level = CreatureLevel.get_new_level(creature, new_experience)

    if new_level > creature.level do
      query =
        from c in Creature,
          where: c.id == ^creature.id,
          update: [set: [level: ^new_level]],
          select: c

      {1, _} = Repo.update_all(query, [])
    end

    :ok
  end

  @doc """
  Caller has to make sure that the creature belongs to the user.
  """
  def spend_attribute_point(%Creature{} = creature, attribute) when attribute in @attributes do
    query = Creature.by_id(creature.id) |> Creature.filter_has_unspent_points()

    case Repo.update_all(query, Creature.spend_attribute_point_update(creature, attribute)) do
      {0, _} -> {:error, :not_enough_points}
      _ -> :ok
    end
  end

  @doc """
  Caller has to make sure that the creature belongs to the user.
  """
  def reset_attribute_points(%Creature{} = creature) do
    creature_res = Res.Creature.get_by_res_id(creature.res_id)

    new_max_health =
      Creature.max_health_from_attributes(creature_res, creature.health_points_wild, 0)

    query =
      from c in Creature,
        where: c.id == ^creature.id,
        update: [
          set: [
            health_points_tamed: 0,
            energy_points_tamed: 0,
            damage_points_tamed: 0,
            resistance_points_tamed: 0,
            max_health: ^new_max_health,
            current_health: fragment("least(?, ?)", c.current_health, ^new_max_health)
          ]
        ]

    {1, _} = Repo.update_all(query, [])
    :ok
  end

  def random_creature(%Res.Creature{} = creature_res, level) do
    {health_points, energy_points, damage_points, resistance_points} = roll_attributes(level - 1)

    max_health = Creature.max_health_from_attributes(creature_res, health_points, 0)

    %Creature{
      res_id: creature_res.res_id,
      current_health: max_health,
      max_health: max_health,
      level: level,
      health_points_wild: health_points,
      energy_points_wild: energy_points,
      damage_points_wild: damage_points,
      resistance_points_wild: resistance_points
    }
  end

  defp roll_attributes(rolls) do
    Stream.repeatedly(fn -> Enum.random(0..4) end)
    |> Stream.take(rolls - 1)
    |> Enum.reduce({0, 0, 0, 0}, fn random_num, {hp, ep, dp, rp} ->
      case random_num do
        0 -> {hp, ep, dp, rp}
        1 -> {hp + 1, ep, dp, rp}
        2 -> {hp, ep + 1, dp, rp}
        3 -> {hp, ep, dp + 1, rp}
        4 -> {hp, ep, dp, rp + 1}
      end
    end)
  end
end
