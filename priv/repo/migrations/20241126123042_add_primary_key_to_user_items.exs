defmodule TamedWilds.Repo.Migrations.AddPrimaryKeyToUserItems do
  use Ecto.Migration

  def change do
    alter table(:user_items) do
      add :id, :identity, autogenerate: true, primary_key: true
    end
  end
end
