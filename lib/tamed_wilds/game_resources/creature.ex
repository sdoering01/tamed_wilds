defmodule TamedWilds.GameResources.Creature do
  alias __MODULE__

  defmodule Taming do
    @enforce_keys [:base_food_value_to_tame, :feeding_interval_ms]
    defstruct [:base_food_value_to_tame, :feeding_interval_ms]
  end

  @enforce_keys [:res_id, :name, :base_max_health, :damage, :base_kill_experience, :loot, :taming]
  defstruct [:res_id, :name, :base_max_health, :damage, :base_kill_experience, :loot, :taming]

  @spec get_by_res_id(integer()) :: %Creature{}
  def get_by_res_id(res_id) do
    get_all() |> Map.get(res_id) || raise "Creature with resource id #{res_id} does not exist"
  end

  def get_base_tame_experience(%Creature{} = creature) do
    ceil(creature.base_kill_experience * 1.5)
  end

  def get_all() do
    %{
      1 => %Creature{
        res_id: 1,
        name: "Sparrow",
        base_max_health: 10,
        damage: 2,
        base_kill_experience: 60,
        loot: %{
          6 => 1,
          7 => 1
        },
        taming: %Taming{
          base_food_value_to_tame: 30,
          feeding_interval_ms: :timer.seconds(10)
        }
      },
      2 => %Creature{
        res_id: 2,
        name: "Rabbit",
        base_max_health: 15,
        damage: 3,
        base_kill_experience: 100,
        loot: %{
          6 => 1,
          8 => 1
        },
        taming: %Taming{
          base_food_value_to_tame: 40,
          feeding_interval_ms: :timer.seconds(10)
        }
      }
    }
  end
end
