defmodule TamedWilds.GameResources.Item do
  alias __MODULE__

  @enforce_keys [:id, :name]
  defstruct [:id, :name]

  def get_by_id(id) do
    get_all() |> Map.get(id) || raise "Item with id #{id} does not exist"
  end

  def get_all do
    %{
      1 => %Item{id: 1, name: "Strange Stone"},
      2 => %Item{id: 2, name: "Gras"},
      3 => %Item{id: 3, name: "Twig"},
      4 => %Item{id: 4, name: "Berry"},
      5 => %Item{id: 5, name: "Berry Jam"},
      6 => %Item{id: 6, name: "Meat"},
      7 => %Item{id: 7, name: "Feather"},
      8 => %Item{id: 8, name: "Hide"}
    }
  end
end
