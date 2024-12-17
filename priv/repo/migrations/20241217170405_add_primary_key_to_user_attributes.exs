defmodule TamedWilds.Repo.Migrations.AddPrimaryKeyToUserAttributes do
  use Ecto.Migration

  def change do
    alter table(:user_attributes) do
      add :id, :identity, autogenerate: true, primary_key: true
    end
  end
end
