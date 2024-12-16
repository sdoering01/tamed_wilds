defmodule TamedWilds.GameResources.Building do
  alias __MODULE__

  @enforce_keys [:id, :name, :slug, :description, :construction_resources]
  defstruct [:id, :name, :slug, :description, :construction_resources]

  def get_by_id(id) do
    get_all() |> Map.get(id) || raise "Building with id #{id} does not exist"
  end

  def get_all() do
    %{
      1 => %Building{
        id: 1,
        name: "Stoneheart",
        slug: "stoneheart",
        description: "The heart of your camp. A strange energy emanates from it.",
        construction_resources: %{1 => 1, 3 => 10}
      },
      2 => %Building{
        id: 2,
        name: "Campfire",
        slug: "campfire",
        description: "A cozy place where you can cook food.",
        construction_resources: %{2 => 10, 3 => 10}
      }
    }
  end
end
