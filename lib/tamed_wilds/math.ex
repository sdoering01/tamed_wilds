defmodule TamedWilds.Math do
  def round_probabilistic(float) when is_float(float) do
    # Verified to work with positive and netagive floats

    floored = floor(float)
    fraction = float - floored

    if :rand.uniform() < fraction do
      floored + 1
    else
      floored
    end
  end
end
