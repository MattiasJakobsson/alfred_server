defmodule Alfred.Workflow.Commands.AddPlugin do
  use Traverse.Steps.Command

  def execute(params) do
    Alfred.Engine.add_plugin(params.definition)
  end
end
