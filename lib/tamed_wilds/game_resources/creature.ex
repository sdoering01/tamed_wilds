defmodule TamedWilds.GameResources.Creature do
  alias __MODULE__

  defmodule Taming do
    @enforce_keys [:feedings, :feeding_interval_ms]
    defstruct [:feedings, :feeding_interval_ms]
  end

  @enforce_keys [:res_id, :name, :max_health, :damage, :kill_experience, :loot, :taming]
  defstruct [:res_id, :name, :max_health, :damage, :kill_experience, :loot, :taming]

  @spec get_by_res_id(integer()) :: %Creature{}
  def get_by_res_id(res_id) do
    get_all() |> Map.get(res_id) || raise "Creature with resource id #{res_id} does not exist"
  end

  def get_tame_experience(%Creature{} = creature) do
    ceil(creature.kill_experience * 1.5)
  end

  def get_all() do
    %{
      1 => %Creature{
        res_id: 1,
        name: "Sparrow",
        max_health: 10,
        damage: 2,
        kill_experience: 60,
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
        res_id: 2,
        name: "Rabbit",
        max_health: 15,
        damage: 3,
        kill_experience: 100,
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
