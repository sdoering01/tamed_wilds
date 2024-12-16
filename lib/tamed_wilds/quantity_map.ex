defmodule TamedWilds.QuantityMap do
  @moduledoc """
  A QuantityMap is a map from (item) ids to quantities.

  This module provides functions for working With quantity maps.
  """

  alias TamedWilds.GameResources.Item

  @doc """
  Checks If the first quantity map contains the second quantity map.

  This can be useful to check whether an inventory contains enough items for a
  recipe.


  ## Examples

      iex> QuantityMap.contains?(%{11 => 1, 12 => 2}, %{12 => 1})
      true

  """
  def contains?(qm1, qm2) do
    Enum.all?(qm2, fn {id, qty} -> Map.get(qm1, id, 0) >= qty end)
  end

  def to_string(qm, kind)

  def to_string(qm, :item) do
    Enum.map(qm, fn {id, qty} -> "#{qty}x#{Item.get_by_id(id).name}" end) |> Enum.join(", ")
  end
end
