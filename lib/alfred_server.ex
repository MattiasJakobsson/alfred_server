defmodule AlfredServer do
  use GenServer

  def init(data) do
    {:ok, data}
  end
end
