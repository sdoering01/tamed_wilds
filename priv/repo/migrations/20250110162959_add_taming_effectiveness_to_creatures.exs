defmodule TamedWilds.Repo.Migrations.AddTamingEffectivenessToCreatures do
  use Ecto.Migration

  def change do
    alter table(:creatures) do
      add :taming_effectiveness, :float, default: 0.0, null: false
    end
  end
end
