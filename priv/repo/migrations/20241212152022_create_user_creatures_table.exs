defmodule TamedWilds.Repo.Migrations.CreateUserCreaturesTable do
  use Ecto.Migration

  def change do
    create table(:user_creatures) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :creature_id, :integer, null: false
      add :name, :string
      add :tamed_at, :utc_datetime_usec, null: false, default: fragment("now()")
    end

    create index(:user_creatures, [:user_id])
  end
end
