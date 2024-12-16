defmodule TamedWildsWeb.Camp.Plugs.EnsureBuildingBuilt do
  use TamedWildsWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  def init([]), do: []

  def call(conn, _opts) do
    if conn.assigns.building_level == 0 do
      conn
      |> put_flash(:error, "#{conn.assigns.current_building.name} not built yet")
      |> redirect(to: ~p"/camp")
      |> halt()
    else
      conn
    end
  end
end
