defmodule TamedWilds.Repo.Migrations.RenameExplorationCreatureSightingsToExplorationCreatures do
  use Ecto.Migration

  def change do
    rename table(:exploration_creature_sightings), to: table(:exploration_creatures)
  end
end
