defmodule TamedWilds.Repo.Migrations.AddExperienceAndLevelToUserAttributes do
  use Ecto.Migration

  def change do
    alter table(:user_attributes) do
      # 8 bytes integer in postgres
      add :experience, :bigint, null: false, default: 0
      add :level, :integer, null: false, default: 1
    end
  end
end
