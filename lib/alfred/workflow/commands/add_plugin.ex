defmodule Alfred.Workflow.Commands.AddPlugin do
  use Traverse.Steps.Step
  
  def run_step(definition, state) do
    plugin = Traverse.ParameterInterpreter.eval_code(definition.plugin, state)

    Alfred.Engine.add_plugin(plugin.definition)
    
    :next
  end
end
