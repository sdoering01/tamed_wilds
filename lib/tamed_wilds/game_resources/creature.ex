defmodule TamedWilds.GameResources.Creature do
  alias __MODULE__

  defmodule Taming do
    @enforce_keys [:feedings, :feeding_interval_ms]
    defstruct [:feedings, :feeding_interval_ms]
  end

  @enforce_keys [:id, :name, :health, :damage, :loot, :taming]
  defstruct [:id, :name, :health, :damage, :loot, :taming]

  def get_by_id(id) do
    get_all() |> Map.get(id) || raise "Creature with id #{id} does not exist"
  end

  def get_all() do
    %{
      1 => %Creature{
        id: 1,
        name: "Sparrow",
        health: 10,
        damage: 2,
        loot: %{
          6 => 1,
          7 => 1
        },
        taming: %Taming{
          feedings: 3,
          feeding_interval_ms: :timer.seconds(10)
        }
      },
      2 => %Creature{
        id: 2,
        name: "Rabbit",
        health: 15,
        damage: 3,
        loot: %{
          6 => 1,
          8 => 1
        },
        taming: %Taming{
          feedings: 3,
          feeding_interval_ms: :timer.seconds(10)
        }
      }
    }
  end
end
