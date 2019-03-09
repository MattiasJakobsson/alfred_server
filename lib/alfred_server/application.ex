defmodule AlfredServer.Application do
  use Application
  use Supervisor

  def start(_type, _args) do
    start_link()
  end

  def start_link() do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      supervisor(Plugin.Repo, []),
      supervisor(Workflow.Repo, []),
      supervisor(AlfredServer, []),
      supervisor(Phoenix.PubSub.PG2, [:alfred, []])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
