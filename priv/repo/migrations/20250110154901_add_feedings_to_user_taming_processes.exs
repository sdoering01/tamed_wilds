defmodule TamedWilds.Repo.Migrations.AddFeedingsToUserTamingProcesses do
  use Ecto.Migration

  def change do
    alter table(:user_taming_processes) do
      add :feedings, :integer, default: 0, null: false
    end
  end
end
