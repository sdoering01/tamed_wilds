defmodule TamedWildsWeb.ExplorationController do
  use TamedWildsWeb, :controller

  alias TamedWilds.{Exploration, UserAttributes, QuantityMap, Camp}

  def index(conn, _params) do
    user_attributes = UserAttributes.get!(conn.assigns.current_user)

    exploration_creature = Exploration.get_exploration_creature(conn.assigns.current_user)

    taming_processes = Exploration.get_taming_processes(conn.assigns.current_user)

    stoneheart_built? = Camp.stoneheart_built?(conn.assigns.current_user)

    render(conn, :exploration,
      user_attributes: user_attributes,
      exploration_creature: exploration_creature,
      taming_processes: taming_processes,
      stoneheart_built?: stoneheart_built?
    )
  end

  def explore(conn, _params) do
    conn =
      case Exploration.explore(conn.assigns.current_user) do
        {:ok, {:found_item, item}} ->
          put_flash(conn, :info, "You explored and found #{item.name}!")

        {:ok, {:found_item_but_inventory_full, item}} ->
          put_flash(
            conn,
            :warning,
            "You explored and found #{item.name}, but your inventory is full!"
          )

        {:error, :not_enough_energy} ->
          put_flash(conn, :error, "You don't have enough energy to explore!")
      end

    redirect(conn, to: ~p"/exploration")
  end

  def send_companion_to_camp(conn, _params) do
    :ok = UserAttributes.clear_companion(conn.assigns.current_user)

    conn |> put_flash(:info, "Sent companion back to camp!") |> redirect(to: ~p"/exploration")
  end

  def attack(conn, _params) do
    # TODO: Maybe include the name of the creature in the flash message

    conn =
      case Exploration.attack_creature(conn.assigns.current_user) do
        {:ok, :user_died} ->
          put_flash(conn, :warning, "You died!")

        {:ok, :creature_hit} ->
          put_flash(conn, :info, "You attacked the creature!")

        {:ok, :creature_defeated} ->
          put_flash(conn, :info, "You deafeated the creature!")

        {:error, :no_creature} ->
          put_flash(conn, :error, "There is no creature to attack!")
      end

    redirect(conn, to: ~p"/exploration")
  end

  def kill(conn, _params) do
    conn =
      case Exploration.kill_creature(conn.assigns.current_user) do
        {:ok, {:creature_killed, loot}} ->
          if map_size(loot) == 0 do
            put_flash(conn, :info, "You killed the creature!")
          else
            loot_string = QuantityMap.to_string(loot, :item)
            put_flash(conn, :info, "You killed the creature and looted: #{loot_string}!")
          end

        {:error, :no_defeated_creature} ->
          put_flash(conn, :error, "There is no defeated creature to kill!")
      end

    redirect(conn, to: ~p"/exploration")
  end

  def tame(conn, _params) do
    conn =
      if Camp.stoneheart_built?(conn.assigns.current_user) do
        case Exploration.start_taming_creature(conn.assigns.current_user) do
          {:ok, :taming_started} ->
            put_flash(conn, :info, "You started taming the creature!")

          {:error, :no_defeated_creature} ->
            put_flash(conn, :error, "There is no defeated creature to tame!")
        end
      else
        put_flash(conn, :error, "You need to build the Stoneheart to tame creatures!")
      end

    conn |> redirect(to: ~p"/exploration")
  end

  def taming_feed(conn, %{"id" => taming_process_id}) do
    conn =
      case Exploration.feed_taming_creature(conn.assigns.current_user, taming_process_id) do
        {:ok, :creature_fed} ->
          put_flash(conn, :info, "You fed the creature!")

        {:ok, :taming_complete} ->
          put_flash(conn, :info, "You successfully tamed the creature!")

        {:error, :cannot_feed_yet} ->
          put_flash(conn, :error, "You can't feed the creature yet!")

        {:error, :not_enough_items} ->
          put_flash(conn, :error, "You don't have enough items to feed the creature!")

        {:error, :taming_process_not_found} ->
          put_flash(conn, :error, "This taming process couldn't be found!")
      end

    conn |> redirect(to: ~p"/exploration")
  end

  def taming_cancel(conn, %{"id" => taming_process_id}) do
    conn =
      case Exploration.cancel_taming_creature(conn.assigns.current_user, taming_process_id) do
        {:ok, :taming_cancelled} ->
          put_flash(conn, :info, "You cancelled the taming process!")

        {:error, :taming_process_not_found} ->
          put_flash(conn, :error, "This taming process couldn't be found!")
      end

    conn |> redirect(to: ~p"/exploration")
  end

  # TODO: Remove this
  def regenerate(conn, _params) do
    UserAttributes.regenerate_energy_of_all_users(10)

    conn |> put_flash(:info, "Regenerated energy") |> redirect(to: ~p"/exploration")
  end
end
