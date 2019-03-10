defmodule Alfred.Workflow.Commands.AddPlugin do
  use Traverse.Steps.ExecuteCommand.Command

  def execute(params) do
    Alfred.Engine.add_plugin(params.definition)
  end
end
