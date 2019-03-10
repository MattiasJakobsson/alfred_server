defmodule Alfred.Workflow.Commands.AddPlugin do
  use Traverse.Workflow.Command

  def execute(params) do
    Alfred.add_plugin(params.definition)
  end
end
