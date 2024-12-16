defmodule TamedWildsWeb.Camp.Plugs.FetchBuildingLevel do
  import Plug.Conn

  alias TamedWilds.Camp
  alias TamedWilds.GameResources.Building

  def init(building_id), do: Building.get_by_id(building_id)

  def call(conn, building) do
    level = Camp.get_building_level(conn.assigns.current_user, building)

    assign(conn, :building_level, level) |> assign(:current_building, building)
  end
end
