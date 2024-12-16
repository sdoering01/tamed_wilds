defmodule TamedWilds.UserAttributes.Regenerator do
  use GenServer

  alias TamedWilds.UserAttributes

  @energy_per_tick 10
  @health_per_tick 10
  @tick_interval :timer.minutes(1)

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(state) do
    queue_regeneration()
    {:ok, state}
  end

  def handle_info(:regenerate, state) do
    queue_regeneration()

    UserAttributes.regenerate_energy_of_all_users(@energy_per_tick)
    UserAttributes.regenerate_health_of_all_users(@health_per_tick)

    {:noreply, state}
  end

  defp queue_regeneration() do
    Process.send_after(self(), :regenerate, @tick_interval)
  end
end
