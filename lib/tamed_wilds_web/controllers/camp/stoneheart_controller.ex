defmodule TamedWildsWeb.Camp.StoneheartController do
  @stoneheart_res_id 1

  use TamedWildsWeb.Camp.Helpers.BuildingController, building_res_id: @stoneheart_res_id

  def index(conn, _params) do
    level = conn.assigns.building_level

    creatures = TamedWilds.Creatures.get_user_creatures(conn.assigns.current_user)

    render(conn, :stoneheart, level: level, creatures: creatures)
  end
end
