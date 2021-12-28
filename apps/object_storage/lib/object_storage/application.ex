defmodule Legendary.ObjectStorage.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Legendary.ObjectStorageWeb.Endpoint

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      Legendary.ObjectStorageWeb.Telemetry,
      # Start the Ecto repository
     Legendary.ObjectStorage.Repo,
     # Start the Endpoint (http/https)
     Legendary.ObjectStorageWeb.Endpoint,
      # Start the PubSub system
      {Phoenix.PubSub, name: Legendary.ObjectStorage.PubSub}
      # Start a worker by calling Legendary.ObjectStorage.Worker.start_link(arg)
      # {ObjectStorage.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Legendary.ObjectStorage.Supervisor)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    Endpoint.config_change(changed, removed)
    :ok
  end
end
