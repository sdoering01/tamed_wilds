defmodule TamedWilds.Repo.Migrations.AddCompanionToUserAttributes do
  use Ecto.Migration

  def change do
    alter table(:user_attributes) do
      add :companion_id, references(:creatures, on_delete: :nilify_all)
    end
  end
end
