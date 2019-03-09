defmodule AlfredServer.Workflow.Commands.AddPlugin do
  use Traverse.Workflow.Command

  def execute(definition) do
    AlfredServer.add_plugin(definition)
  end
end
