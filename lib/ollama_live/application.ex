defmodule OllamaLive.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      OllamaLiveWeb.Telemetry,
      OllamaLive.Repo,
      {DNSCluster, query: Application.get_env(:ollama_live, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: OllamaLive.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: OllamaLive.Finch},
      # Start a worker by calling: OllamaLive.Worker.start_link(arg)
      # {OllamaLive.Worker, arg},
      # Start to serve requests, typically the last entry
      OllamaLiveWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: OllamaLive.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    OllamaLiveWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
