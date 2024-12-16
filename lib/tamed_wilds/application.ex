defmodule TamedWilds.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TamedWildsWeb.Telemetry,
      TamedWilds.Repo,
      {DNSCluster, query: Application.get_env(:tamed_wilds, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: TamedWilds.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: TamedWilds.Finch},
      # Start a worker by calling: TamedWilds.Worker.start_link(arg)
      # {TamedWilds.Worker, arg},
      TamedWilds.UserAttributes.Regenerator,
      # Start to serve requests, typically the last entry
      TamedWildsWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TamedWilds.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TamedWildsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
