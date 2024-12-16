defmodule TamedWilds.Inventory do
  alias TamedWilds.Repo
  import Ecto.Query

  alias TamedWilds.Accounts.User
  alias TamedWilds.GameResources, as: Res
  alias TamedWilds.Inventory.UserItems
  alias TamedWilds.UserAttributes

  def get_items(%User{} = user) do
    user_items = UserItems.by_user(user) |> Repo.all()

    user_items
    |> Enum.map(fn user_item ->
      item = Res.Item.get_by_res_id(user_item.item_res_id)
      %{item: item, quantity: user_item.quantity}
    end)
  end

  def get_item_quantity_map(%User{} = user) do
    UserItems.by_user(user) |> Repo.all() |> Enum.map(&{&1.item_res_id, &1.quantity}) |> Map.new()
  end

  def add_item(%User{} = user, %Res.Item{} = item, quantity) do
    # Could potentially be a bottleneck If the inventory size is queried for
    # each added item
    %{inventory_size: inventory_size} = UserAttributes.get!(user)

    user_items = %UserItems{
      user_id: user.id,
      item_res_id: item.res_id,
      # Cap quantity to inventory_size when adding new items
      quantity: min(quantity, inventory_size)
    }

    # Limits the quantity of an item to the inventory size, but does not delete
    # items that already exceed the inventory size
    conflict_query =
      from ui in UserItems,
        update: [
          set: [quantity: fragment("least(?, ?)", ui.quantity + ^quantity, ^inventory_size)]
        ],
        where: ui.quantity < ^inventory_size

    returned_user_items =
      Repo.insert!(user_items,
        conflict_target: [:user_id, :item_res_id],
        on_conflict: conflict_query,
        # Needed, since the query might fail to insert a new item, If the stac
        # is already full
        allow_stale: true,
        returning: true
      )

    # If partial addition of items to the inventory has to be detected, the
    # `user_items` entry has to be fetched first

    # When upserting the `user_items` and the row in the database was not
    # updated, then the same struct is returned and does not have the `id`
    # field set, since this field is auto-generated by the database. The
    # returned row from the database has the `id` field set.
    #
    # NOTE: This does not detect partial additions!
    items_added? = returned_user_items.id != nil

    if items_added? do
      :ok
    else
      {:error, :inventory_full}
    end
  end

  def add_items(%User{} = user, item_quantity_map) do
    Repo.transact(fn ->
      Enum.each(item_quantity_map, fn {item_res_id, quantity} ->
        item = Res.Item.get_by_res_id(item_res_id)

        # For now, ignore when the inventory is full
        add_item(user, item, quantity)
      end)

      :ok
    end)
    |> case do
      {:ok, _} -> :ok
      error -> error
    end
  end

  def remove_items(%User{} = user, item_quantity_map) do
    Repo.transact(fn ->
      Enum.each(item_quantity_map, fn {item_res_id, quantity} ->
        item = Res.Item.get_by_res_id(item_res_id)

        case remove_item(user, item, quantity) do
          {:error, :not_enough_items} -> Repo.rollback(:not_enough_items)
          :ok -> :ok
        end
      end)
    end)
    |> case do
      {:ok, _} -> :ok
      error -> error
    end
  end

  def remove_item(%User{} = user, %Res.Item{} = item, quantity) do
    query =
      from ui in UserItems,
        where:
          ui.user_id == ^user.id and ui.item_res_id == ^item.res_id and ui.quantity >= ^quantity

    case Repo.update_all(query, inc: [quantity: -quantity]) do
      {0, _} -> {:error, :not_enough_items}
      {_, _} -> :ok
    end
  end
end
