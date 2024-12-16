defmodule TamedWildsWeb.Camp.Helpers.BuildingController do
  defmacro __using__(opts) do
    building_id = Keyword.fetch!(opts, :building_id)

    quote do
      use TamedWildsWeb, :controller

      plug TamedWildsWeb.Camp.Plugs.FetchBuildingLevel, unquote(building_id)
      plug TamedWildsWeb.Camp.Plugs.EnsureBuildingBuilt
    end
  end
end
