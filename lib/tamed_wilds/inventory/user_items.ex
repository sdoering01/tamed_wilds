defmodule TamedWilds.Inventory.UserItems do
  use Ecto.Schema
  import Ecto.Query
  alias __MODULE__

  schema "user_items" do
    field :quantity, :integer
    field :item_id, :integer

    belongs_to :user, TamedWilds.Accounts.User
  end

  def by_user(user) do
    from ui in UserItems,
      where: ui.user_id == ^user.id,
      where: ui.quantity > 0,
      order_by: [asc: ui.item_id]
  end
end
