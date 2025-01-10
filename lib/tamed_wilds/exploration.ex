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

  @experience_factor_increase_per_creature_level 0.1

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

    creature = get_exploration_creature(user).creature

    base_damage_by_user = 2

    damage_by_user =
      base_damage_by_user * UserAttributes.outgoing_damage_factor(user_attributes)

    damage_by_companion =
      if is_nil(companion),
        do: 0,
        else:
          Res.Creature.get_by_res_id(companion.res_id).damage *
            Creature.outgoing_damage_factor(companion)

    damage_to_creature =
      (damage_by_user + damage_by_companion) * Creature.incoming_damage_factor(creature)

    query = ExplorationCreature.do_damage_query(user, round(damage_to_creature))

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

            damage_by_creature =
              creature_res.damage * Creature.outgoing_damage_factor(creature)

            damage_to_user =
              damage_by_creature * UserAttributes.incoming_damage_factor(user_attributes)

            if not is_nil(companion) do
              damage_to_companion =
                damage_by_creature * Creature.incoming_damage_factor(creature)

              {:ok, _} =
                UserAttributes.do_damage_to_companion(user, companion, round(damage_to_companion))
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
          {1, [%Creature{} = creature]} =
            Creature.delete_by_id_query(creature_id) |> Repo.delete_all()

          creature_res = Res.Creature.get_by_res_id(creature.res_id)
          loot = creature_res.loot

          kill_experience =
            round(creature_res.base_kill_experience * experience_factor(creature.level))

          :ok = Inventory.add_items(user, loot)
          :ok = UserAttributes.add_experience(user, kill_experience)

          companion = UserAttributes.get_companion(user)

          if not is_nil(companion) do
            :ok = Creatures.add_experience(companion, kill_experience)
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
          food_value_to_tame = Creature.food_value_to_tame(creature_res, creature.level)

          user_taming_process = %UserTamingProcess{
            user_id: user.id,
            creature_id: creature_id,
            started_at: now,
            next_feeding_at:
              DateTime.add(now, creature_res.taming.feeding_interval_ms, :millisecond),
            food_value_to_tame: food_value_to_tame
          }

          {:ok, _} = Repo.insert(user_taming_process)
          {:ok, :taming_started}
      end
    end)
  end

  def feed_taming_creature(%User{} = user, taming_process_id, food_item_res_id) do
    query =
      UserTamingProcess.by_user_and_id(user, taming_process_id)
      |> UserTamingProcess.with_creature()

    now = DateTime.utc_now()

    case Repo.one(query) do
      %UserTamingProcess{} = taming_process ->
        if DateTime.after?(taming_process.next_feeding_at, now) do
          {:error, :cannot_feed_yet}
        else
          food_item_res = Res.Item.get_by_res_id(food_item_res_id)
          food_value = get_in(food_item_res.creature_food.value)

          if is_nil(food_value) do
            {:error, :not_a_food}
          else
            Repo.transact(fn ->
              case Inventory.remove_item(user, food_item_res, 1) do
                :ok ->
                  query =
                    UserTamingProcess.by_user_and_id(user, taming_process_id)
                    # Prevents feeding multiple times
                    |> UserTamingProcess.where_next_feeding_before(now)

                  creature_res = Res.Creature.get_by_res_id(taming_process.creature.res_id)

                  if taming_process.current_food_value + food_value >=
                       taming_process.food_value_to_tame do
                    {1, _} = Repo.delete_all(query)

                    # include the current feeding that is not reflected in the database yet
                    taming_effectiveness =
                      TamedWilds.Exploration.Taming.taming_effectiveness_factor(
                        taming_process.feedings + 1
                      )

                    {:ok, _} =
                      Creatures.tame_creature(
                        user,
                        taming_process.creature,
                        now,
                        taming_effectiveness
                      )

                    experience_gain =
                      round(
                        Res.Creature.get_base_tame_experience(creature_res) *
                          experience_factor(taming_process.creature.level)
                      )

                    :ok = UserAttributes.add_experience(user, experience_gain)

                    {:ok, :taming_complete}
                  else
                    next_feeding_at =
                      DateTime.add(now, creature_res.taming.feeding_interval_ms, :millisecond)

                    case Repo.update_all(query,
                           set: [next_feeding_at: next_feeding_at],
                           inc: [current_food_value: food_value, feedings: 1]
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

      creature = Creatures.random_creature(creature_res, creature_level)

      %ExplorationCreature{
        user_id: user.id,
        creature: creature
      }
      |> Repo.insert(on_conflict: :replace_all, conflict_target: [:user_id])
    end
  end

  defp experience_factor(level) do
    1 + @experience_factor_increase_per_creature_level * (level - 1)
  end
end
