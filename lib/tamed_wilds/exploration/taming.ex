defmodule TamedWilds.Exploration.Taming do
  def taming_effectiveness_factor(feedings) do
    25 / (25 + feedings)
  end

  def level_gain(level, taming_effectiveness) do
    floor(level * taming_effectiveness / 2)
  end
end
