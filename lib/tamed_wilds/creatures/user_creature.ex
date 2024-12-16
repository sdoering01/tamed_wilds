defmodule TamedWilds.Creatures.UserCreature do
  use Ecto.Schema
  import Ecto.Query

  alias __MODULE__
  alias TamedWilds.Accounts.User

  schema "user_creatures" do
    field :creature_res_id, :integer
    field :name, :string
    field :tamed_at, :utc_datetime_usec

    belongs_to :user, TamedWilds.Accounts.User
  end

  def by_user(%User{} = user) do
    from uc in UserCreature, where: uc.user_id == ^user.id
  end
end
