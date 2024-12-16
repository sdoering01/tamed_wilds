defmodule TamedWildsWeb.Camp.CampfireController do
  @campfire_id 2

  use TamedWildsWeb.Camp.Helpers.BuildingController, building_id: @campfire_id

  alias TamedWilds.Inventory
  alias TamedWilds.GameResources.{CampfireRecipe, Item}
  alias TamedWilds.Camp.Buildings.Campfire
  alias TamedWilds.UserAttributes

  def index(conn, _params) do
    level = conn.assigns.building_level

    recipes = CampfireRecipe.get_all() |> Map.values()
    item_quantity_map = Inventory.get_item_quantity_map(conn.assigns.current_user)

    %{inventory_size: inventory_size} = UserAttributes.get!(conn.assigns.current_user)

    render(conn, :campfire,
      level: level,
      recipes: recipes,
      item_quantity_map: item_quantity_map,
      inventory_size: inventory_size
    )
  end

  def craft(conn, %{"recipe_id" => recipe_id}) do
    recipe = recipe_id |> String.to_integer() |> CampfireRecipe.get_by_id()
    %{name: name} = Item.get_by_id(recipe.result)

    conn =
      case Campfire.craft(conn.assigns.current_user, recipe) do
        :ok -> conn |> put_flash(:info, "Crafted #{name}")
        {:error, :inventory_full} -> conn |> put_flash(:error, "Inventory full")
        {:error, :not_enough_items} -> conn |> put_flash(:error, "Not enough items")
      end

    conn |> redirect(to: ~p"/camp/campfire")
  end
end
