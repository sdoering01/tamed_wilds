defmodule TamedWildsWeb.CharacterController do
  use TamedWildsWeb, :controller

  alias TamedWilds.UserAttributes

  def index(conn, _params) do
    user_attributes = UserAttributes.get!(conn.assigns.current_user)

    render(conn, "character.html", user_attributes: user_attributes)
  end

  def spend_attribute_point(conn, %{"attribute" => attribute}) do
    attribute = String.to_existing_atom(attribute)

    conn =
      case UserAttributes.spend_attribute_point(conn.assigns.current_user, attribute) do
        :ok ->
          put_flash(conn, :info, "Spent point on #{attribute}!")

        {:error, :not_enough_points} ->
          put_flash(conn, :error, "Not enough points")
      end

    redirect(conn, to: ~p"/character")
  end

  def reset_attribute_points(conn, _params) do
    :ok = UserAttributes.reset_attribute_points(conn.assigns.current_user)

    conn |> put_flash(:info, "Reset attribute points!") |> redirect(to: ~p"/character")
  end
end
