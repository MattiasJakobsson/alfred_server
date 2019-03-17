defmodule Alfred.Workflow.Commands.AddPlugin do
  use Traverse.Steps.Step
  
  def run_step(definition, state) do
    plugin_definition = Traverse.ParameterInterpreter.eval_code(definition.plugin, state)

    Alfred.Engine.add_plugin(plugin_definition)
    
    :next
  end
end
