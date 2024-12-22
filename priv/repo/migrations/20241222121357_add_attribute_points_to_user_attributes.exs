defmodule TamedWilds.Repo.Migrations.AddAttributePointsToUserAttributes do
  use Ecto.Migration

  def change do
    alter table(:user_attributes) do
      add :health_points, :integer, default: 0, null: false
      add :energy_points, :integer, default: 0, null: false
      add :damage_points, :integer, default: 0, null: false
      add :resistance_points, :integer, default: 0, null: false
    end
  end
end
