defmodule TamedWilds.Repo.Migrations.AddExperienceAndLevelToCreatures do
  use Ecto.Migration

  def change do
    alter table(:creatures) do
      add :experience, :integer, null: false, default: 0
      add :level, :integer, null: false
      add :level_after_tamed, :integer
    end
  end
end
