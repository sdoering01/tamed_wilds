defmodule TamedWildsWeb.Camp.Plugs.FetchBuildingLevel do
  import Plug.Conn

  alias TamedWilds.Camp
  alias TamedWilds.GameResources, as: Res

  def init(building_res_id), do: Res.Building.get_by_res_id(building_res_id)

  def call(conn, building) do
    level = Camp.get_building_level(conn.assigns.current_user, building)

    assign(conn, :building_level, level) |> assign(:current_building, building)
  end
end
