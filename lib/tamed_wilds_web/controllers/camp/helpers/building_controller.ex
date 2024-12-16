defmodule TamedWildsWeb.Camp.Helpers.BuildingController do
  defmacro __using__(opts) do
    building_res_id = Keyword.fetch!(opts, :building_res_id)

    quote do
      use TamedWildsWeb, :controller

      plug TamedWildsWeb.Camp.Plugs.FetchBuildingLevel, unquote(building_res_id)
      plug TamedWildsWeb.Camp.Plugs.EnsureBuildingBuilt
    end
  end
end
