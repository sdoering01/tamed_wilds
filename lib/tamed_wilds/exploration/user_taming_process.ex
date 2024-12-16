defmodule TamedWilds.Exploration.UserTamingProcess do
  use Ecto.Schema
  import Ecto.Query

  alias __MODULE__
  alias TamedWilds.Accounts.User

  schema "user_taming_processes" do
    field :creature_res_id, :integer
    field :started_at, :utc_datetime_usec
    field :next_feeding_at, :utc_datetime_usec
    field :feedings_left, :integer

    belongs_to :user, TamedWilds.Accounts.User
  end

  def by_user(%User{} = user) do
    from utp in UserTamingProcess, where: utp.user_id == ^user.id
  end

  def by_user_and_id(%User{} = user, id) do
    from utp in UserTamingProcess, where: utp.user_id == ^user.id, where: utp.id == ^id
  end

  def where_next_feeding_at_before(%Ecto.Query{} = query, now) do
    from utp in query, where: utp.next_feeding_at < ^now
  end
end
