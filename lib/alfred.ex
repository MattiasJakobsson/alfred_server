defmodule Alfred do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    opts = [strategy: :one_for_one, name: Alfred.Supervisor]

    children = [
      supervisor(Alfred.Engine, []),
      supervisor(Phoenix.PubSub.PG2, [:alfred, []])
    ]

    Supervisor.start_link(children, opts)
  end
end
