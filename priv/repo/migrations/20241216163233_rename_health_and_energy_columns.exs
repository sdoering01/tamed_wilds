defmodule TamedWilds.Repo.Migrations.RenameHealthAndEnergyColumns do
  use Ecto.Migration

  def change do
    rename table(:user_attributes), :health, to: :current_health
    rename table(:user_attributes), :energy, to: :current_energy
  end
end
