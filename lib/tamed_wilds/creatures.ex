defmodule TamedWilds.Creatures do
  alias TamedWilds.Accounts.User
  alias TamedWilds.GameResources, as: Res
  alias TamedWilds.Creatures.UserCreature
  alias TamedWilds.Repo

  def get_user_creatures(%User{} = user) do
    UserCreature.by_user(user) |> Repo.all()
  end

  def add_creature_to_user(%User{} = user, %Res.Creature{} = creature, tamed_at \\ nil) do
    tamed_at = if is_nil(tamed_at), do: DateTime.utc_now(), else: tamed_at

    Repo.insert(%UserCreature{
      user_id: user.id,
      creature_res_id: creature.res_id,
      tamed_at: tamed_at
    })
  end
end
