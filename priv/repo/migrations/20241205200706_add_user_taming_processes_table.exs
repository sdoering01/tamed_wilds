defmodule TamedWilds.Repo.Migrations.AddUserTamingProcessesTable do
  use Ecto.Migration

  def change do
    create table(:user_taming_processes) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :creature_id, :integer, null: false
      add :started_at, :utc_datetime_usec, null: false, default: fragment("now()")
      add :next_feeding_at, :utc_datetime_usec, null: false
      add :feedings_left, :integer, null: false
    end

    create index(:user_taming_processes, [:user_id])
  end
end
