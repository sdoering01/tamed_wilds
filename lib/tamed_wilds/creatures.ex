defmodule TamedWilds.Creatures do
  import Ecto.Query

  alias TamedWilds.Accounts.User
  alias TamedWilds.Creatures.{Creature, CreatureLevel}
  alias TamedWilds.Repo
  alias TamedWilds.GameResources, as: Res

  @attributes Creature.attributes()

  def get_user_creatures(%User{} = user) do
    Creature.tamed_by_user(user) |> Repo.all()
  end

  def tame_creature(%User{} = user, %Creature{} = creature, tamed_at \\ nil) do
    tamed_at = if is_nil(tamed_at), do: DateTime.utc_now(), else: tamed_at

    creature |> Creature.tame_changeset(user, tamed_at) |> Repo.update()
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
end
