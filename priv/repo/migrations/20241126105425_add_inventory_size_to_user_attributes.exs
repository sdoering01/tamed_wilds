defmodule TamedWilds.Repo.Migrations.AddInventorySizeToUserAttributes do
  use Ecto.Migration

  def change do
    alter table(:user_attributes) do
      add :inventory_size, :integer, default: 50, null: false
    end
  end
end
