defmodule TamedWilds.Exploration do
  alias Ecto.Repo
  import Ecto.Query
  alias TamedWilds.Repo
  alias TamedWilds.GameResources.{Item, Creature}
  alias TamedWilds.Accounts.User
  alias TamedWilds.{Inventory, UserAttributes, Creatures}
  alias TamedWilds.Exploration.{ExplorationCreature, UserTamingProcess}

  @loot_table Item.get_all() |> Map.take([2, 3, 4]) |> Map.values()

  @creature_table Creature.get_all() |> Map.values()

  def get_exploration_creature(%User{} = user) do
    ExplorationCreature.by_user(user) |> Repo.one()
  end

  def get_taming_processes(%User{} = user) do
    UserTamingProcess.by_user(user) |> Repo.all()
  end

  def explore(%User{} = user) do
    Repo.transact(fn ->
      with :ok <- UserAttributes.reduce_energy(user, 1) do
        item = @loot_table |> Enum.random()

        maybe_trigger_creature_sighting(user)

        case Inventory.add_item(user, item, 1) do
          :ok -> {:ok, {:found_item, item}}
          {:error, :inventory_full} -> {:ok, {:found_item_but_inventory_full, item}}
        end
      end
    end)
  end

  def attack_creature(%User{} = user) do
    damage_by_user = 2

    query =
      ExplorationCreature.by_user(user)
      |> ExplorationCreature.do_damage(damage_by_user)

    query = from ec in query, select: ec

    Repo.transact(fn ->
      case Repo.update_all(query, []) do
        {0, _} ->
          {:error, :no_creature}

        {1, [%ExplorationCreature{creature_id: creature_id, health: new_health}]} ->
          if new_health <= 0 do
            {:ok, :creature_defeated}
          else
            creature = Creature.get_by_id(creature_id)

            case UserAttributes.do_damage(user, creature.damage) do
              {:ok, :dead} ->
                {1, _} = ExplorationCreature.by_user(user) |> Repo.delete_all()
                {:ok, :user_died}

              {:ok, :alive} ->
                {:ok, :creature_hit}
            end
          end
      end
    end)
  end

  def kill_creature(%User{} = user) do
    query = ExplorationCreature.by_user(user) |> ExplorationCreature.filter_defeated()
    query = from ec in query, select: ec

    Repo.transact(fn ->
      case Repo.delete_all(query) do
        {0, _} ->
          {:error, :no_defeated_creature}

        {1, [%ExplorationCreature{creature_id: creature_id}]} ->
          creature = Creature.get_by_id(creature_id)
          loot = creature.loot

          case Inventory.add_items(user, loot) do
            :ok -> {:ok, {:creature_killed, loot}}
          end
      end
    end)
  end

  def start_taming_creature(%User{} = user) do
    query = ExplorationCreature.by_user(user) |> ExplorationCreature.filter_defeated()
    query = from ec in query, select: ec

    Repo.transact(fn ->
      case Repo.delete_all(query) do
        {0, _} ->
          {:error, :no_defeated_creature}

        {1, [%ExplorationCreature{creature_id: creature_id}]} ->
          creature = Creature.get_by_id(creature_id)

          now = DateTime.utc_now()

          user_taming_process = %UserTamingProcess{
            user_id: user.id,
            creature_id: creature.id,
            started_at: now,
            next_feeding_at: DateTime.add(now, creature.taming.feeding_interval_ms, :millisecond),
            feedings_left: creature.taming.feedings
          }

          {:ok, _} = Repo.insert(user_taming_process)
          {:ok, :taming_started}
      end
    end)
  end

  def feed_taming_creature(%User{} = user, taming_process_id) do
    query = UserTamingProcess.by_user_and_id(user, taming_process_id)

    now = DateTime.utc_now()

    case Repo.one(query) do
      %UserTamingProcess{} = taming_process ->
        if DateTime.after?(taming_process.next_feeding_at, now) do
          {:error, :cannot_feed_yet}
        else
          berry = Item.get_by_id(4)

          Repo.transact(fn ->
            case Inventory.remove_item(user, berry, 1) do
              :ok ->
                query =
                  UserTamingProcess.by_user_and_id(user, taming_process_id)
                  # Prevents feeding multiple times
                  |> UserTamingProcess.where_next_feeding_at_before(now)

                creature = Creature.get_by_id(taming_process.creature_id)

                if taming_process.feedings_left <= 1 do
                  {1, _} = Repo.delete_all(query)
                  {:ok, _} = Creatures.add_creature_to_user(user, creature, now)
                  {:ok, :taming_complete}
                else
                  next_feeding_at =
                    DateTime.add(now, creature.taming.feeding_interval_ms, :millisecond)

                  case Repo.update_all(query,
                         set: [next_feeding_at: next_feeding_at],
                         inc: [feedings_left: -1]
                       ) do
                    {1, _} ->
                      {:ok, :creature_fed}

                    {0, _} ->
                      {:error, :taming_process_not_found}
                  end
                end

              {:error, :not_enough_items} ->
                {:error, :not_enough_items}
            end
          end)
        end

      nil ->
        {:error, :taming_process_not_found}
    end
  end

  def cancel_taming_creature(%User{} = user, taming_process_id) do
    query = UserTamingProcess.by_user_and_id(user, taming_process_id)

    case Repo.delete_all(query) do
      {0, _} ->
        {:error, :taming_process_not_found}

      {1, _} ->
        {:ok, :taming_cancelled}
    end
  end

  defp maybe_trigger_creature_sighting(user) do
    if Enum.random(1..100) <= 10 do
      creature = @creature_table |> Enum.random()

      %ExplorationCreature{
        creature_id: creature.id,
        user_id: user.id,
        health: creature.health,
        max_health: creature.health
      }
      |> Repo.insert(on_conflict: :replace_all, conflict_target: [:user_id])
    end
  end
end
