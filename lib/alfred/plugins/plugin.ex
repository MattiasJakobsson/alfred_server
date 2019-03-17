defmodule Alfred.Plugins.Plugin do
  @callback start_discover() :: :ok
  
  defmodule Definition do
    defstruct type: nil,
              id: nil,
              name: nil,
              settings: %{}
  end
  
  def start_discover_from(plugin_type) when is_binary(plugin_type) do
    start_discover_from(String.to_existing_atom("Elixir.#{plugin_type}"))
  end

  def start_discover_from(plugin_type) when is_atom(plugin_type) do
    apply(plugin_type, :start_discover, [])
  end
  
  def initialize_plugin(definition) do
    {:ok, plugin} = GenServer.start_link(
      definition.type,
      definition.settings,
      name: {:global, definition.id}
    )

    {:ok, plugin}
  end
  
  defmacro __using__(_) do
    quote location: :keep do
      use GenServer
      @behaviour Alfred.Plugins.Plugin
    end
  end

  defmacro __before_compile__(env) do
    unless Module.defines?(env.module, {:start_discover, 0}) do
      quote do
        def start_discover(), do: :ok

        defoverridable start_discover: 0
      end
    end

    unless Module.defines?(env.module, {:init, 1}) do
      quote do
        def init(definition), do: {:ok, definition}

        defoverridable init: 1
      end
    end
  end
end
