defmodule TamedWilds.GameResources.CampfireRecipe do
  alias __MODULE__

  @enforce_keys [:id, :ingredients, :result]
  defstruct [:id, :ingredients, :result]

  def get_by_id(id) do
    get_all() |> Map.get(id) || raise "Campfire recipe with id #{id} does not exist"
  end

  def get_all() do
    %{
      1 => %CampfireRecipe{
        id: 1,
        ingredients: %{
          4 => 5,
          3 => 5
        },
        result: 5
      }
    }
  end
end
