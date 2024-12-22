defmodule TamedWilds.Repo.Migrations.AddAttributePointsToCreatures do
  use Ecto.Migration

  def change do
    alter table(:creatures) do
      add :health_points, :integer, null: false
      add :energy_points, :integer, null: false
      add :damage_points, :integer, null: false
      add :resistance_points, :integer, null: false

      add :health_points_after_tamed, :integer
      add :energy_points_after_tamed, :integer
      add :damage_points_after_tamed, :integer
      add :resistance_points_after_tamed, :integer
    end
  end
end
