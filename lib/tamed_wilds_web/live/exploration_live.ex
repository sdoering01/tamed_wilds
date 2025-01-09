defmodule TamedWildsWeb.ExplorationLive do
  use TamedWildsWeb, :live_view

  alias TamedWilds.{Exploration, UserAttributes, QuantityMap, Camp, Inventory}
  alias TamedWilds.GameResources, as: Res

  def render(assigns) do
    ~H"""
    <h2 class="page-title mb-2">Exploration</h2>

    <div class="mb-4">
      <div>
        <% experience_for_current_level =
          TamedWilds.UserAttributes.UserLevel.get_experience_for_level(@user_attributes.level) %>
        <% experience_for_next_level =
          TamedWilds.UserAttributes.UserLevel.get_experience_for_level(@user_attributes.level + 1) %>
        <% unspent_points = TamedWilds.UserAttributes.unspent_points(@user_attributes) %>
        <p>Level: <%= @user_attributes.level %></p>
        <%= if unspent_points > 0 do %>
          <p>
            <i>
              You have <%= unspent_points %> unspent attribute <%= if unspent_points == 1,
                do: "point",
                else: "points" %>.
            </i>
            <.link href={~p"/character"} class="inline-flex items-center text-primary">
              Spend <span class="hero-chevron-right-mini"></span>
            </.link>
          </p>
        <% end %>
        <progress
          class="progress progress-primary w-56"
          value={@user_attributes.experience - experience_for_current_level}
          max={experience_for_next_level - experience_for_current_level}
        >
        </progress>
      </div>
      <div>
        <progress
          class="progress progress-warning w-56"
          value={@user_attributes.current_energy}
          max={@user_attributes.max_energy}
        >
        </progress>
        <p>Energy: <%= @user_attributes.current_energy %> / <%= @user_attributes.max_energy %></p>

        <progress
          class="progress progress-success w-56"
          value={@user_attributes.current_health}
          max={@user_attributes.max_health}
        >
        </progress>
        <p>Health: <%= @user_attributes.current_health %> / <%= @user_attributes.max_health %></p>
      </div>
    </div>

    <%= if @user_attributes.companion do %>
      <% companion = @user_attributes.companion %>
      <% experience_for_current_level =
        TamedWilds.Creatures.CreatureLevel.get_experience_for_level(companion, companion.level) %>
      <% experience_for_next_level =
        TamedWilds.Creatures.CreatureLevel.get_experience_for_level(companion, companion.level + 1) %>
      <% unspent_points = TamedWilds.Creatures.Creature.unspent_points(companion) %>

      <div class="mb-4">
        <p>
          Companion: <%= Res.Creature.get_by_res_id(companion.res_id).name %> (Level <%= companion.level %>)
        </p>
        <%= if unspent_points > 0 do %>
          <p>
            <i>
              Your companion has <%= unspent_points %> unspent attribute <%= if unspent_points == 1,
                do: "point",
                else: "points" %>.
            </i>
            <.link
              href={~p"/camp/stoneheart/creatures/#{companion.id}"}
              class="inline-flex items-center text-primary"
            >
              Spend <span class="hero-chevron-right-mini"></span>
            </.link>
          </p>
        <% end %>
        <progress
          class="progress progress-primary w-56"
          value={companion.experience - experience_for_current_level}
          max={experience_for_next_level - experience_for_current_level}
        >
        </progress> <br />
        <progress
          class="progress progress-success w-56"
          value={companion.current_health}
          max={companion.max_health}
        >
        </progress>
        <p>Health: <%= companion.current_health %> / <%= companion.max_health %></p>
        <button phx-click="send_companion_to_camp" class="btn btn-secondary btn-sm">
          Send back to Camp
        </button>
      </div>
    <% else %>
      <%= if @stoneheart_built? do %>
        <p class="mb-4">
          <i>No companion chosen.</i>
          <.link href={~p"/camp/stoneheart"} class="inline-flex items-center text-primary">
            Go to Stoneheart <span class="hero-chevron-right-mini"></span>
          </.link>
        </p>
      <% end %>
    <% end %>

    <div class="flex items-center gap-1">
      <%= if @user_attributes.current_energy > 0 do %>
        <button phx-click="explore" class="btn btn-primary">Explore</button>
      <% else %>
        <div class="tooltip" data-tip="No energy">
          <button class="btn btn-primary" disabled>Explore</button>
        </div>
      <% end %>

      <.link href={~p"/exploration/regenerate"} method="post" class="btn btn-primary">
        DEV: Regenerate Energy of all Users
      </.link>
    </div>

    <%= if @exploration_creature do %>
      <% creature_res = Res.Creature.get_by_res_id(@exploration_creature.creature.res_id) %>
      <div class="mt-4">
        <h3 class="text-lg">
          <%= creature_res.name %> (Level <%= @exploration_creature.creature.level %>)
        </h3>

        <%= if @exploration_creature.creature.current_health > 0 do %>
          <progress
            class="progress progress-error w-56"
            value={@exploration_creature.creature.current_health}
            max={@exploration_creature.creature.max_health}
          >
          </progress>
          <p>
            Health: <%= @exploration_creature.creature.current_health %> / <%= @exploration_creature.creature.max_health %>
          </p>
          <button phx-click="attack" class="btn btn-primary">Attack</button>
        <% else %>
          <p class="text-error">Defeated</p>
          <div class="flex items-center gap-1">
            <button phx-click="kill" class="btn btn-primary">Kill</button>

            <%= if @stoneheart_built? do %>
              <button phx-click="tame" class="btn btn-secondary">Tame</button>
            <% else %>
              <div class="tooltip" data-tip="First construct Stonheart in Camp">
                <button class="btn btn-secondary" disabled>Tame</button>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    <% end %>

    <%= if not Enum.empty?(@taming_processes) do %>
      <hr class="mt-8" />
      <h3 class="text-xl mt-4 mb-2">Taming</h3>
      <ul>
        <%= for taming_process <- @taming_processes do %>
          <% creature_res = Res.Creature.get_by_res_id(taming_process.creature.res_id) %>
          <% seconds_left = DateTime.diff(taming_process.next_feeding_at, @cached_now) %>

          <li>
            <p><%= creature_res.name %> (Level <%= taming_process.creature.level %>)</p>
            <progress
              class="progress progress-primary w-56"
              value={taming_process.current_food_value}
              max={taming_process.food_value_to_tame}
            >
            </progress>
            <br />
            <%= if seconds_left > 0 do %>
              <button class="btn btn-primary" disabled>
                <%= seconds_left %>s until next feeding
              </button>
            <% else %>
              <%= if map_size(@food_quantity_map) > 0 do %>
                <%= for {item_res_id, quantity} <- @food_quantity_map do %>
                  <button
                    phx-click="taming_feed"
                    phx-value-tp-id={taming_process.id}
                    phx-value-item-res-id={item_res_id}
                    class="btn btn-primary"
                  >
                    Feed <%= Res.Item.get_by_res_id(item_res_id).name %> (<%= quantity %>)
                  </button>
                <% end %>
              <% else %>
                <button class="btn btn-primary" disabled>No food available</button>
              <% end %>
            <% end %>
            <button
              phx-click="taming_cancel"
              phx-value-id={taming_process.id}
              data-confirm={"Do you really want to cancel taming #{creature_res.name}?"}
              class="btn btn-secondary"
            >
              Cancel
            </button>
          </li>
        <% end %>
      </ul>
    <% end %>
    """
  end

  def mount(_params, _session, socket) do
    socket = fetch_and_assign_data(socket) |> assign_cached_now()

    queue_tick()

    {:ok, socket}
  end

  def handle_event("explore", %{}, socket) do
    socket = clear_flash(socket)

    socket =
      case Exploration.explore(socket.assigns.current_user) do
        {:ok, {:found_item, item}} ->
          socket
          |> put_flash(:info, "You explored and found #{item.name}!")
          |> fetch_and_assign_data()

        {:ok, {:found_item_but_inventory_full, item}} ->
          socket
          |> put_flash(
            :warning,
            "You explored and found #{item.name}, but your inventory is full!"
          )
          |> fetch_and_assign_data()

        {:error, :not_enough_energy} ->
          put_flash(socket, :error, "You don't have enough energy to explore!")
      end

    {:noreply, socket}
  end

  def handle_event("send_companion_to_camp", %{}, socket) do
    socket = clear_flash(socket)

    :ok = UserAttributes.clear_companion(socket.assigns.current_user)

    {:noreply,
     socket
     |> put_flash(:info, "Sent companion back to camp!")
     |> assign(user_attributes: %{socket.assigns.user_attributes | companion: nil})}
  end

  def handle_event("attack", %{}, socket) do
    # TODO: Maybe include the name of the creature in the flash message
    socket = clear_flash(socket)

    socket =
      case Exploration.attack_creature(socket.assigns.current_user) do
        {:ok, :user_died} ->
          socket |> put_flash(:warning, "You died!") |> fetch_and_assign_data()

        {:ok, :creature_hit} ->
          socket |> put_flash(:info, "You attacked the creature!") |> fetch_and_assign_data()

        {:ok, :creature_defeated} ->
          socket |> put_flash(:info, "You deafeated the creature!") |> fetch_and_assign_data()

        {:error, :no_creature} ->
          put_flash(socket, :error, "There is no creature to attack!")
      end

    {:noreply, socket}
  end

  def handle_event("kill", %{}, socket) do
    socket = clear_flash(socket)

    socket =
      case Exploration.kill_creature(socket.assigns.current_user) do
        {:ok, {:creature_killed, loot}} ->
          if map_size(loot) == 0 do
            put_flash(socket, :info, "You killed the creature!")
          else
            loot_string = QuantityMap.to_string(loot, :item)
            put_flash(socket, :info, "You killed the creature and looted: #{loot_string}!")
          end
          |> fetch_and_assign_data()

        {:error, :no_defeated_creature} ->
          put_flash(socket, :error, "There is no defeated creature to kill!")
      end

    {:noreply, socket}
  end

  def handle_event("tame", %{}, socket) do
    socket = clear_flash(socket)

    socket =
      if socket.assigns.stoneheart_built? do
        case Exploration.start_taming_creature(socket.assigns.current_user) do
          {:ok, :taming_started} ->
            socket
            |> put_flash(:info, "You started taming the creature!")
            |> fetch_and_assign_data()

          {:error, :no_defeated_creature} ->
            put_flash(socket, :error, "There is no defeated creature to tame!")
        end
      else
        put_flash(socket, :error, "You need to build the Stoneheart to tame creatures!")
      end

    {:noreply, assign_cached_now(socket)}
  end

  def handle_event(
        "taming_feed",
        %{"tp-id" => taming_process_id, "item-res-id" => item_res_id},
        socket
      ) do
    item_res_id = String.to_integer(item_res_id)

    socket = clear_flash(socket)

    socket =
      case Exploration.feed_taming_creature(
             socket.assigns.current_user,
             taming_process_id,
             item_res_id
           ) do
        {:ok, :creature_fed} ->
          socket
          |> put_flash(:info, "You fed the creature!")
          |> fetch_and_assign_data()

        {:ok, :taming_complete} ->
          socket
          |> put_flash(:info, "You successfully tamed the creature!")
          |> fetch_and_assign_data()

        {:error, :cannot_feed_yet} ->
          put_flash(socket, :error, "You can't feed the creature yet!")

        {:error, :not_enough_items} ->
          put_flash(socket, :error, "You don't have enough items to feed the creature!")

        {:error, :not_a_food} ->
          put_flash(socket, :error, "This item is not a food!")

        {:error, :taming_process_not_found} ->
          put_flash(socket, :error, "This taming process couldn't be found!")
      end

    {:noreply, assign_cached_now(socket)}
  end

  def handle_event("taming_cancel", %{"id" => taming_process_id}, socket) do
    socket = clear_flash(socket)

    socket =
      case Exploration.cancel_taming_creature(socket.assigns.current_user, taming_process_id) do
        {:ok, :taming_cancelled} ->
          socket
          |> put_flash(:info, "You cancelled the taming process!")
          |> fetch_and_assign_data()

        {:error, :taming_process_not_found} ->
          put_flash(socket, :error, "This taming process couldn't be found!")
      end

    {:noreply, socket}
  end

  def handle_info(:tick, socket) do
    queue_tick()

    any_feeding_on_cooldown? =
      Enum.any?(socket.assigns.taming_processes, fn tp ->
        DateTime.after?(tp.next_feeding_at, socket.assigns.cached_now)
      end)

    # Only trigger update when there are taming processes
    socket =
      if any_feeding_on_cooldown? do
        assign_cached_now(socket)
      else
        socket
      end

    {:noreply, socket}
  end

  defp queue_tick(), do: Process.send_after(self(), :tick, 1000)

  defp assign_cached_now(socket), do: assign(socket, :cached_now, DateTime.utc_now())

  defp fetch_and_assign_data(socket) do
    user_attributes = UserAttributes.get!(socket.assigns.current_user)
    exploration_creature = Exploration.get_exploration_creature(socket.assigns.current_user)
    taming_processes = Exploration.get_taming_processes(socket.assigns.current_user)
    stoneheart_built? = Camp.stoneheart_built?(socket.assigns.current_user)
    creature_food_list = Res.Item.get_creature_food_list()
    item_quantity_map = Inventory.get_item_quantity_map(socket.assigns.current_user)

    food_quantity_map =
      Map.take(
        item_quantity_map,
        get_in(creature_food_list, [Access.all(), Access.key!(:res_id)])
      )

    assign(socket,
      user_attributes: user_attributes,
      exploration_creature: exploration_creature,
      taming_processes: taming_processes,
      stoneheart_built?: stoneheart_built?,
      food_quantity_map: food_quantity_map
    )
  end
end
