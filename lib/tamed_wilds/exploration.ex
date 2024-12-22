defmodule TamedWilds.Exploration do
  alias TamedWilds.Creatures.Creature
  alias Ecto.Repo
  alias TamedWilds.Repo
  alias TamedWilds.GameResources, as: Res
  alias TamedWilds.Accounts.User
  alias TamedWilds.{Inventory, UserAttributes, Creatures}
  alias TamedWilds.Exploration.{ExplorationCreature, UserTamingProcess}

  @loot_table Res.Item.get_all() |> Map.take([2, 3, 4]) |> Map.values()

  @creature_table Res.Creature.get_all() |> Map.values()

  def get_exploration_creature(%User{} = user) do
    ExplorationCreature.by_user(user) |> ExplorationCreature.with_creature() |> Repo.one()
  end

  def get_taming_processes(%User{} = user) do
    UserTamingProcess.by_user(user) |> UserTamingProcess.with_creature() |> Repo.all()
  end

  def explore(%User{} = user) do
    Repo.transact(fn ->
      with :ok <- UserAttributes.reduce_energy(user, 1) do
        item = @loot_table |> Enum.random()

        maybe_trigger_creature_sighting(user)

        experience_gain = 5
        :ok = UserAttributes.add_experience(user, experience_gain)

        companion = UserAttributes.get_companion(user)

        if not is_nil(companion) do
          :ok = Creatures.add_experience(companion, experience_gain)
        end

        case Inventory.add_item(user, item, 1) do
          :ok -> {:ok, {:found_item, item}}
          {:error, :inventory_full} -> {:ok, {:found_item_but_inventory_full, item}}
        end
      end
    end)
  end

  def attack_creature(%User{} = user) do
    user_attributes =
      UserAttributes.by_user(user) |> UserAttributes.with_companion() |> Repo.one!()

    companion = user_attributes.companion

    damage_by_user = 2 * UserAttributes.outgoing_damage_percentage(user_attributes) / 100

    damage_by_companion =
      if is_nil(companion), do: 0, else: Res.Creature.get_by_res_id(companion.res_id).damage

    query = ExplorationCreature.do_damage_query(user, round(damage_by_user + damage_by_companion))

    Repo.transact(fn ->
      case Repo.update_all(query, []) do
        {0, _} ->
          {:error, :no_creature}

        {1,
         [
           %Creature{res_id: creature_res_id, current_health: new_health}
         ]} ->
          if new_health <= 0 do
            {:ok, :creature_defeated}
          else
            creature_res = Res.Creature.get_by_res_id(creature_res_id)
            damage_by_creature = creature_res.damage

            damage_to_user =
              damage_by_creature * UserAttributes.incoming_damage_percentage(user_attributes) /
                100

            if not is_nil(companion) do
              {:ok, _} =
                UserAttributes.do_damage_to_companion(user, companion, damage_by_creature)
            end

            case UserAttributes.do_damage(user, round(damage_to_user)) do
              {:ok, :dead} ->
                # Also deletes exploration creature via cascade
                {1, _} = Repo.delete_all(ExplorationCreature.associated_creature_query(user))

                {:ok, :user_died}

              {:ok, :alive} ->
                {:ok, :creature_hit}
            end
          end
      end
    end)
  end

  def kill_creature(%User{} = user) do
    query = ExplorationCreature.delete_defeated_query(user)

    Repo.transact(fn ->
      case Repo.delete_all(query) do
        {0, _} ->
          {:error, :no_defeated_creature}

        {1, [%ExplorationCreature{creature_id: creature_id}]} ->
          # Safety: We can delete by ID since we already made sure that the
          # exploration creature exists, is defeated and belongs to the user
          {1, [%Creature{res_id: creature_res_id}]} =
            Creature.delete_by_id_query(creature_id) |> Repo.delete_all()

          creature_res = Res.Creature.get_by_res_id(creature_res_id)
          loot = creature_res.loot

          :ok = Inventory.add_items(user, loot)
          :ok = UserAttributes.add_experience(user, creature_res.kill_experience)

          companion = UserAttributes.get_companion(user)

          if not is_nil(companion) do
            :ok = Creatures.add_experience(companion, creature_res.kill_experience)
          end

          {:ok, {:creature_killed, loot}}
      end
    end)
  end

  def start_taming_creature(%User{} = user) do
    query = ExplorationCreature.delete_defeated_query(user)

    Repo.transact(fn ->
      case Repo.delete_all(query) do
        {0, _} ->
          {:error, :no_defeated_creature}

        {1, [%ExplorationCreature{creature_id: creature_id}]} ->
          creature = Repo.get!(Creature, creature_id)
          creature_res = Res.Creature.get_by_res_id(creature.res_id)

          now = DateTime.utc_now()

          user_taming_process = %UserTamingProcess{
            user_id: user.id,
            creature_id: creature_id,
            started_at: now,
            next_feeding_at:
              DateTime.add(now, creature_res.taming.feeding_interval_ms, :millisecond),
            feedings_left: creature_res.taming.feedings
          }

          {:ok, _} = Repo.insert(user_taming_process)
          {:ok, :taming_started}
      end
    end)
  end

  def feed_taming_creature(%User{} = user, taming_process_id) do
    query =
      UserTamingProcess.by_user_and_id(user, taming_process_id)
      |> UserTamingProcess.with_creature()

    now = DateTime.utc_now()

    case Repo.one(query) do
      %UserTamingProcess{} = taming_process ->
        if DateTime.after?(taming_process.next_feeding_at, now) do
          {:error, :cannot_feed_yet}
        else
          berry = Res.Item.get_by_res_id(4)

          Repo.transact(fn ->
            case Inventory.remove_item(user, berry, 1) do
              :ok ->
                query =
                  UserTamingProcess.by_user_and_id(user, taming_process_id)
                  # Prevents feeding multiple times
                  |> UserTamingProcess.where_next_feeding_before(now)

                creature_res = Res.Creature.get_by_res_id(taming_process.creature.res_id)

                if taming_process.feedings_left <= 1 do
                  {1, _} = Repo.delete_all(query)
                  {:ok, _} = Creatures.tame_creature(user, taming_process.creature, now)

                  experience_gain = Res.Creature.get_tame_experience(creature_res)
                  :ok = UserAttributes.add_experience(user, experience_gain)

                  {:ok, :taming_complete}
                else
                  next_feeding_at =
                    DateTime.add(now, creature_res.taming.feeding_interval_ms, :millisecond)

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
      # Clear existing creatures -- we don't care about errors
      _ = Repo.delete_all(ExplorationCreature.associated_creature_query(user))

      creature_res = @creature_table |> Enum.random()

      # TODO: Get this from the GameResource of the exploration area
      creature_level = Enum.random(1..5)

      creature = %Creature{
        res_id: creature_res.res_id,
        current_health: creature_res.max_health,
        max_health: creature_res.max_health,
        level: creature_level
      }

      %ExplorationCreature{
        user_id: user.id,
        creature: creature
      }
      |> Repo.insert(on_conflict: :replace_all, conflict_target: [:user_id])
    end
  end
end
