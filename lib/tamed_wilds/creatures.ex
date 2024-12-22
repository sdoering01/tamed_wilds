defmodule TamedWilds.Creatures do
  import Ecto.Query

  alias TamedWilds.Accounts.User
  alias TamedWilds.Creatures.{Creature, CreatureLevel}
  alias TamedWilds.Repo

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
                c.current_health + c.max_health * ^by_factor,
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
end
