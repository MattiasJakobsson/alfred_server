defmodule AlfredServer.Application do
  @target Mix.target()

  use Application

  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: AlfredServer.Supervisor]
    Supervisor.start_link(children(@target), opts)
  end

  defp children(:host) do
    [
      {AlfredServer, []}
    ]
  end

  defp children(_target) do
    [
      {AlfredServer, []}
    ]
  end
end
