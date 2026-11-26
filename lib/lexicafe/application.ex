defmodule Lexicafe.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Lexicafe.Repo,
      {Phoenix.PubSub, name: Lexicafe.PubSub},
      {Registry, keys: :unique, name: Lexicafe.GameRegistry},
      {DynamicSupervisor, name: Lexicafe.GameSupervisor, strategy: :one_for_one},
      LexicafeWeb.Presence,
      LexicafeWeb.Endpoint
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Lexicafe.Supervisor)
  end

  @impl true
  def config_change(changed, _new, removed) do
    LexicafeWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
