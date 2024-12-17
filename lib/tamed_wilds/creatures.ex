defmodule TamedWilds.Creatures do
  import Ecto.Query

  alias TamedWilds.Accounts.User
  alias TamedWilds.Creatures.Creature
  alias TamedWilds.Repo

  def get_user_creatures(%User{} = user) do
    Creature.tamed_by_user(user) |> Repo.all()
  end

  def add_creature_to_user(%User{} = user, %Creature{} = creature, tamed_at \\ nil) do
    tamed_at = if is_nil(tamed_at), do: DateTime.utc_now(), else: tamed_at

    creature |> Creature.tame_changeset(user, tamed_at) |> Repo.update()
  end

  def regenerate_health_of_tamed_creatures(by_percentage) do
    query =
      from c in Creature,
        where: not is_nil(c.tamed_by),
        where: c.current_health < c.max_health,
        update: [
          set: [
            current_health:
              fragment(
                "least(ceil(?), ?)",
                # 100.0 is used to force float division
                c.current_health + c.max_health * ^by_percentage / 100.0,
                c.max_health
              )
          ]
        ]

    Repo.update_all(query, [])
  end
end
