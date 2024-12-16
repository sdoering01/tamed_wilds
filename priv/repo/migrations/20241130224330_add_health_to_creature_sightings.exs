defmodule TamedWilds.Repo.Migrations.AddHealthToCreatureSightings do
  use Ecto.Migration

  def change do
    alter table(:exploration_creature_sightings) do
      add :health, :integer, null: false
      add :max_health, :integer, null: false
    end
  end
end
