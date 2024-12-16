defmodule TamedWilds.GameResources.CampfireRecipe do
  alias __MODULE__

  @enforce_keys [:res_id, :ingredients, :result]
  defstruct [:res_id, :ingredients, :result]

  def get_by_res_id(res_id) do
    get_all() |> Map.get(res_id) ||
      raise "Campfire recipe with resource id #{res_id} does not exist"
  end

  def get_all() do
    %{
      1 => %CampfireRecipe{
        res_id: 1,
        ingredients: %{
          4 => 5,
          3 => 5
        },
        result: 5
      }
    }
  end
end
