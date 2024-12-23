defmodule TamedWilds.Repo.Migrations.RenameCreatureAttributeColumns do
  use Ecto.Migration

  def change do
    rename table(:creatures), :health_points_after_tamed, to: :health_points_wild
    rename table(:creatures), :energy_points_after_tamed, to: :energy_points_wild
    rename table(:creatures), :damage_points_after_tamed, to: :damage_points_wild
    rename table(:creatures), :resistance_points_after_tamed, to: :resistance_points_wild

    rename table(:creatures), :health_points, to: :health_points_tamed
    rename table(:creatures), :energy_points, to: :energy_points_tamed
    rename table(:creatures), :damage_points, to: :damage_points_tamed
    rename table(:creatures), :resistance_points, to: :resistance_points_tamed

    alter table(:creatures) do
      modify :health_points_tamed, :integer, null: false, default: 0
      modify :energy_points_tamed, :integer, null: false, default: 0
      modify :damage_points_tamed, :integer, null: false, default: 0
      modify :resistance_points_tamed, :integer, null: false, default: 0
    end
  end
end
