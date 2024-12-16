defmodule TamedWilds.Repo.Migrations.CreateExplorationCreatureSightingsTable do
  use Ecto.Migration

  def change do
    create table(:exploration_creature_sightings) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :creature_id, :integer, null: false
    end

    create unique_index(:exploration_creature_sightings, [:user_id])
  end
end
