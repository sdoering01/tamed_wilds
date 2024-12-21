defmodule TamedWilds.UserAttributes.UserLevel do
  defmodule CompileTime do
    @max_level 30

    def calculate_level_experiences do
      Stream.iterate({1, 0}, fn {level, experience} ->
        next_level = level + 1
        next_experience = experience + level * 100
        {next_level, next_experience}
      end)
      |> Enum.take(@max_level)
      |> Enum.map(&elem(&1, 1))
      |> List.to_tuple()
    end

    def max_level() do
      @max_level
    end
  end

  @level_experiences CompileTime.calculate_level_experiences()

  def get_experience_for_level(level) do
    elem(@level_experiences, level - 1)
  end

  def has_level_up?(current_level, new_experience) do
    if current_level >= CompileTime.max_level() do
      false
    else
      new_experience >= get_experience_for_level(current_level + 1)
    end
  end

  @doc """
  Returns the new level based on the new experience.

  The level, before the experience was added, is passed as the first argument.
  """
  def get_new_level(current_level, new_experience) do
    if has_level_up?(current_level, new_experience) do
      get_new_level(current_level + 1, new_experience)
    else
      current_level
    end
  end
end
