defmodule TamedWilds.Repo.Migrations.CreateCreaturesTable do
  use Ecto.Migration

  def change do
    create table(:creatures) do
      add :res_id, :integer, null: false
      add :current_health, :integer, null: false
      add :max_health, :integer, null: false

      add :tamed_at, :utc_datetime_usec
      add :tamed_by, references(:users, on_delete: :delete_all)
    end

    create index(:creatures, [:tamed_by])

    alter table(:exploration_creatures) do
      add :creature_id, references(:creatures, on_delete: :delete_all), null: false

      remove :creature_res_id, :integer, null: false
      remove :health, :integer, null: false
      remove :max_health, :integer, null: false
    end

    alter table(:user_taming_processes) do
      add :creature_id, references(:creatures, on_delete: :delete_all), null: false

      remove :creature_res_id, :integer, null: false
    end

    drop table(:user_creatures)
  end
end
