defmodule TamedWildsWeb.Camp.StoneheartController do
  @stoneheart_res_id 1

  use TamedWildsWeb.Camp.Helpers.BuildingController, building_res_id: @stoneheart_res_id

  alias TamedWilds.{UserAttributes, Creatures}

  def index(conn, _params) do
    level = conn.assigns.building_level

    user_attributes = UserAttributes.get!(conn.assigns.current_user)

    creatures = Creatures.get_user_creatures(conn.assigns.current_user)

    render(conn, :stoneheart,
      level: level,
      creatures: creatures,
      companion_id: user_attributes.companion_id
    )
  end

  def choose_companion(conn, %{"creature_id" => creature_id}) do
    conn =
      case UserAttributes.set_companion(conn.assigns.current_user, creature_id) do
        {:error, :creature_not_found} ->
          put_flash(conn, :error, "This does not exist!")

        {:error, :not_tamed_by_user} ->
          put_flash(conn, :error, "You haven't tamed this creature!")

        :ok ->
          put_flash(conn, :info, "Companion chosen!")
      end

    redirect(conn, to: ~p"/camp/stoneheart")
  end

  def leave_companion(conn, _params) do
    :ok = UserAttributes.set_companion(conn.assigns.current_user, nil)

    conn |> put_flash(:info, "Companion will stay in Camp!") |> redirect(to: ~p"/camp/stoneheart")
  end
end
