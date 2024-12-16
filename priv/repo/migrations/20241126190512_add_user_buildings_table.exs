defmodule TamedWilds.Repo.Migrations.AddUserBuildingsTable do
  use Ecto.Migration

  def change do
    create table(:user_buildings, primary_key: false) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :building_id, :integer, null: false
      add :level, :integer, default: 1, null: false
    end

    create unique_index(:user_buildings, [:user_id, :building_id])
    create index(:user_buildings, [:user_id])
  end
end
