defmodule TamedWilds.Creatures.CreatureLevel do
  require Logger

  alias TamedWilds.Creatures.Creature

  defmodule CompileTime do
    @max_level_ups_after_tamed 20

    def calculate_level_experiences do
      Stream.iterate({0, 0}, fn {level_ups, experience} ->
        next_level_ups = level_ups + 1
        next_experience = experience + (level_ups + 1) * 100
        {next_level_ups, next_experience}
      end)
      # `+ 1` because "level up 0" is already included
      |> Enum.take(@max_level_ups_after_tamed + 1)
      |> Enum.map(&elem(&1, 1))
      |> List.to_tuple()
    end

    def max_level_ups_after_tamed() do
      @max_level_ups_after_tamed
    end
  end

  @level_experiences CompileTime.calculate_level_experiences()

  def max_level_ups_after_tamed() do
    CompileTime.max_level_ups_after_tamed()
  end

  def get_experience_for_level(%Creature{} = creature, new_level) do
    diff = new_level - creature.level_after_tamed

    if diff < 0 do
      Logger.warning(
        "Checked creature experience for level that is lower than the level after taming",
        new_level: new_level,
        level_after_tamed: creature.level_after_tamed
      )

      0
    else
      elem(@level_experiences, diff)
    end
  end

  def has_level_up?(%Creature{} = creature, new_experience) do
    current_level_ups = creature.level_after_tamed - creature.level

    if current_level_ups >= CompileTime.max_level_ups_after_tamed() do
      false
    else
      new_experience >= get_experience_for_level(creature, creature.level + 1)
    end
  end

  @doc """
  Returns the new level based on the new experience.

  The level, before the experience was added, is passed as the first argument.
  """
  def get_new_level(%Creature{} = creature, new_experience) do
    if has_level_up?(creature, new_experience) do
      get_new_level(%{creature | level: creature.level + 1}, new_experience)
    else
      creature.level
    end
  end
end
