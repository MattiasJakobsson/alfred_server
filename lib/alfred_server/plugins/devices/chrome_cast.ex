defmodule AlfredServer.Plugins.Devices.ChromeCast do
  use AlfredServer.Plugins.Plugin

  def discover() do
    []
  end

  def init(data) do
    {:ok, data}
  end
end
