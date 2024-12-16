defmodule TamedWilds.GameResources.Item do
  alias __MODULE__

  @enforce_keys [:res_id, :name]
  defstruct [:res_id, :name]

  def get_by_res_id(res_id) do
    get_all() |> Map.get(res_id) || raise "Item with resource id #{res_id} does not exist"
  end

  def get_all do
    %{
      1 => %Item{res_id: 1, name: "Strange Stone"},
      2 => %Item{res_id: 2, name: "Gras"},
      3 => %Item{res_id: 3, name: "Twig"},
      4 => %Item{res_id: 4, name: "Berry"},
      5 => %Item{res_id: 5, name: "Berry Jam"},
      6 => %Item{res_id: 6, name: "Meat"},
      7 => %Item{res_id: 7, name: "Feather"},
      8 => %Item{res_id: 8, name: "Hide"}
    }
  end
end
