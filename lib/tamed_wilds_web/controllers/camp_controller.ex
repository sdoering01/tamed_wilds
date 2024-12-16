defmodule TamedWildsWeb.CampController do
  use TamedWildsWeb, :controller

  alias TamedWilds.{Camp, Inventory}
  alias TamedWilds.GameResources, as: Res

  def index(conn, _params) do
    building_entries = Camp.get_all_buildings(conn.assigns.current_user)
    item_quantity_map = Inventory.get_item_quantity_map(conn.assigns.current_user)

    render(conn, :camp,
      building_entries: building_entries,
      item_quantity_map: item_quantity_map
    )
  end

  def construct(conn, %{"building_res_id" => building_res_id}) do
    building = building_res_id |> String.to_integer() |> Res.Building.get_by_res_id()

    conn =
      case Camp.construct_building(conn.assigns.current_user, building) do
        :ok ->
          conn |> put_flash(:info, "Building constructed successfully")

        {:error, :not_enough_items} ->
          conn |> put_flash(:error, "Not enough items to construct building")

        {:error, :already_constructed} ->
          conn |> put_flash(:error, "Building already constructed")
      end

    conn |> redirect(to: ~p"/camp")
  end
end
