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

  @experience_increase_factor_per_creature_level 0.1

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

      creature = random_creature(creature_res, creature_level)

      %ExplorationCreature{
        user_id: user.id,
        creature: creature
      }
      |> Repo.insert(on_conflict: :replace_all, conflict_target: [:user_id])
    end
  end

  defp random_creature(%Res.Creature{} = creature_res, level) do
    {health_points, energy_points, damage_points, resistance_points} = randomize_attributes(level)

    # Set health points to max health
    max_health =
      round(
        creature_res.max_health *
          (1 + health_points * Creature.health_factor_increase_per_health_point_untamed())
      )

    creature = %Creature{
      res_id: creature_res.res_id,
      current_health: max_health,
      max_health: max_health,
      level: level,
      health_points: health_points,
      energy_points: energy_points,
      damage_points: damage_points,
      resistance_points: resistance_points
    }

    creature
  end

  defp randomize_attributes(level) do
    Stream.repeatedly(fn -> Enum.random(1..4) end)
    |> Stream.take(level - 1)
    |> Enum.reduce({0, 0, 0, 0}, fn random_num, {hp, ep, dp, rp} ->
      case random_num do
        1 -> {hp + 1, ep, dp, rp}
        2 -> {hp, ep + 1, dp, rp}
        3 -> {hp, ep, dp + 1, rp}
        4 -> {hp, ep, dp, rp + 1}
      end
    end)
  end

  defp experience_factor(level) do
    1 + @experience_increase_factor_per_creature_level * (level - 1)
  end
end
