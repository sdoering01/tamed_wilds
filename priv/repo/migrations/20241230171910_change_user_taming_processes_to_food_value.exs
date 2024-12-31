defmodule TamedWilds.Repo.Migrations.ChangeUserTamingProcessesToFoodValue do
  use Ecto.Migration

  def change do
    alter table(:user_taming_processes) do
      remove :feedings_left, :integer, null: false
      add :current_food_value, :integer, null: false, default: 0
      add :food_value_to_tame, :integer, null: false
    end
  end
end
