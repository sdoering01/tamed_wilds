defmodule TamedWilds.Repo.Migrations.AddUserAttributes do
  use Ecto.Migration

  def change do
    create table(:user_attributes, primary_key: false) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :energy, :integer, default: 100, null: false
      add :max_energy, :integer, default: 100, null: false
    end

    create unique_index(:user_attributes, [:user_id])
  end
end
