defmodule TamedWilds.Repo.Migrations.AddUserItemsTable do
  use Ecto.Migration

  def change do
    create table(:user_items, primary_key: false) do
      add :user_id, references(:users, on_delete: :delete_all)
      add :item_id, :integer, null: false
      add :quantity, :integer, default: 0, null: false
    end

    create index(:user_items, [:user_id])
    create unique_index(:user_items, [:user_id, :item_id])
  end
end
