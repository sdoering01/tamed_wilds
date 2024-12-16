defmodule TamedWilds.Repo.Migrations.AddHealthToUserAttributes do
  use Ecto.Migration

  def change do
    alter table(:user_attributes) do
      add :health, :integer, default: 100, null: false
      add :max_health, :integer, default: 100, null: false
    end
  end
end
