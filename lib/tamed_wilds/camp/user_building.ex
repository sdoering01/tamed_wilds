defmodule TamedWilds.Camp.UserBuilding do
  use Ecto.Schema
  import Ecto.Query

  alias __MODULE__

  @primary_key false
  schema "user_buildings" do
    belongs_to :user, TamedWilds.Accounts.User

    field :building_id, :integer
    field :level, :integer
  end

  def by_user(user) do
    from ub in UserBuilding,
      where: ub.user_id == ^user.id,
      order_by: [asc: ub.building_id],
      where: ub.level > 0
  end

  def level_by_user_and_building_id(user, building_id) do
    from ub in UserBuilding,
      where: ub.user_id == ^user.id,
      where: ub.building_id == ^building_id,
      select: ub.level
  end
end
