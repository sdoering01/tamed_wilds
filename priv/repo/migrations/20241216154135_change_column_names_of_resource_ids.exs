defmodule TamedWilds.Repo.Migrations.ChangeColumnNamesOfResourceIds do
  use Ecto.Migration

  def change do
    rename table(:exploration_creatures), :creature_id, to: :creature_res_id

    rename table(:user_buildings), :building_id, to: :building_res_id

    rename table(:user_creatures), :creature_id, to: :creature_res_id

    rename table(:user_items), :item_id, to: :item_res_id

    rename table(:user_taming_processes), :creature_id, to: :creature_res_id
  end
end
