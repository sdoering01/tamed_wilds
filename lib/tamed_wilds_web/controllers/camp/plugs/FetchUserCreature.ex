defmodule TamedWildsWeb.Camp.Plugs.FetchUserCreature do
  use TamedWildsWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  alias TamedWilds.Creatures.Creature
  alias TamedWilds.Repo

  def init([]), do: []

  def call(conn, _opts) do
    creature = Creature.by_id(conn.params["creature_id"]) |> Repo.one()

    if is_nil(creature) do
      conn
      |> put_flash(:error, "This creature does not exist!")
      |> redirect(to: ~p"/camp/stoneheart")
      |> halt()
    else
      if creature.tamed_by != conn.assigns.current_user.id do
        conn
        |> put_flash(:error, "You haven't tamed this creature!")
        |> redirect(to: ~p"/camp/stoneheart")
        |> halt()
      else
        assign(conn, :current_creature, creature)
      end
    end
  end
end
