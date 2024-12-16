defmodule TamedWilds.Camp.Buildings.Campfire do
  alias TamedWilds.Repo
  alias TamedWilds.Accounts.User
  alias TamedWilds.GameResources, as: Res
  alias TamedWilds.Inventory

  def craft(%User{} = user, %Res.CampfireRecipe{} = recipe) do
    result_item = Res.Item.get_by_res_id(recipe.result)

    Repo.transact(fn ->
      with :ok <- Inventory.remove_items(user, recipe.ingredients),
           :ok <- Inventory.add_item(user, result_item, 1) do
        :ok
      end
    end)
    |> case do
      {:ok, _} -> :ok
      error -> error
    end
  end
end
