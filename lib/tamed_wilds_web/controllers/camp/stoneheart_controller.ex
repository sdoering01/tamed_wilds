defmodule TamedWildsWeb.Camp.StoneheartController do
  @stoneheart_id 1

  use TamedWildsWeb.Camp.Helpers.BuildingController, building_id: @stoneheart_id

  def index(conn, _params) do
    level = conn.assigns.building_level

    user_creatures = TamedWilds.Creatures.get_user_creatures(conn.assigns.current_user)

    render(conn, :stoneheart, level: level, user_creatures: user_creatures)
  end
end
