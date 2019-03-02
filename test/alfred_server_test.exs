defmodule AlfredServerTest do
  use ExUnit.Case
  doctest AlfredServer

  test "greets the world" do
    assert AlfredServer.hello() == :world
  end
end
