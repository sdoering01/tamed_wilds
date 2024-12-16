defmodule TamedWildsWeb.InventoryController do
  use TamedWildsWeb, :controller

  alias TamedWilds.UserAttributes

  def index(conn, _params) do
    inventory_entries = TamedWilds.Inventory.get_items(conn.assigns.current_user)
    attributes = UserAttributes.get!(conn.assigns.current_user)

    render(conn, :inventory,
      inventory_entries: inventory_entries,
      inventory_size: attributes.inventory_size
    )
  end
end
