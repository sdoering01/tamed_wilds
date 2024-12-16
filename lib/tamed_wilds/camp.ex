defmodule TamedWilds.Camp do
  alias TamedWilds.Camp.UserBuilding
  alias TamedWilds.GameResources, as: Res
  alias TamedWilds.{Repo, Inventory}
  alias TamedWilds.Accounts.User

  def get_all_buildings(%User{} = user) do
    user_building_levels =
      UserBuilding.by_user(user)
      |> Repo.all()
      |> Enum.map(fn ub -> {ub.building_res_id, ub.level} end)
      |> Map.new()

    buildings = Res.Building.get_all()

    buildings
    |> Map.values()
    |> Enum.map(fn building ->
      %{building: building, level: Map.get(user_building_levels, building.res_id, 0)}
    end)
  end

  def get_building_level(%User{} = user, %Res.Building{} = building) do
    UserBuilding.level_by_user_and_building_res_id(user, building.res_id) |> Repo.one() || 0
  end

  def stoneheart_built?(%User{} = user) do
    get_building_level(user, Res.Building.get_by_res_id(1)) > 0
  end

  def construct_building(%User{} = user, %Res.Building{} = building) do
    target_level = 1

    current_level = get_building_level(user, building)

    if current_level > 0 do
      {:error, :already_constructed}
    else
      Repo.transact(fn ->
        with :ok <- Inventory.remove_items(user, building.construction_resources) do
          Repo.insert!(%UserBuilding{
            user_id: user.id,
            building_res_id: building.res_id,
            level: target_level
          })

          :ok
        end
      end)
      |> case do
        {:ok, _} -> :ok
        error -> error
      end
    end
  end
end
