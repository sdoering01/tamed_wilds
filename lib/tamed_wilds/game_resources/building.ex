defmodule TamedWilds.GameResources.Building do
  alias __MODULE__

  @enforce_keys [:res_id, :name, :slug, :description, :construction_resources]
  defstruct [:res_id, :name, :slug, :description, :construction_resources]

  def get_by_res_id(res_id) do
    get_all() |> Map.get(res_id) || raise "Building with resource id #{res_id} does not exist"
  end

  def get_all() do
    %{
      1 => %Building{
        res_id: 1,
        name: "Stoneheart",
        slug: "stoneheart",
        description: "The heart of your camp. A strange energy emanates from it.",
        construction_resources: %{1 => 1, 3 => 10}
      },
      2 => %Building{
        res_id: 2,
        name: "Campfire",
        slug: "campfire",
        description: "A cozy place where you can cook food.",
        construction_resources: %{2 => 10, 3 => 10}
      }
    }
  end
end
