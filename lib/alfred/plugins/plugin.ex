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
  
  def query_plugin(plugin_id, query_name, parameters) when is_binary(query_name) do
    query_plugin(plugin_id, String.to_atom(query_name), parameters)
  end

  def query_plugin(plugin_id, query_name, parameters) when is_atom(query_name) do
    GenServer.call({:global, plugin_id}, {query_name, parameters})
  end
  
  def execute_plugin_command(plugin_id, command_name, parameters) when is_binary(command_name) do
    execute_plugin_command(plugin_id, String.to_atom(command_name), parameters)
  end
  
  def execute_plugin_command(plugin_id, command_name, parameters) when is_atom(command_name) do
    GenServer.cast({:global, plugin_id}, {command_name, parameters})
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
    quote do
      use GenServer
      import unquote(__MODULE__)
      
      @behaviour unquote(__MODULE__)

      Module.register_attribute(__MODULE__, :commands, accumulate: false, persist: true)
      Module.register_attribute(__MODULE__, :queries, accumulate: false, persist: true)
      
      @commands []
      @queries []

      def get_available_commands() do
        Keyword.get(__MODULE__.__info__(:attributes), :commands, [])
      end

      def get_available_queries() do
        Keyword.get(__MODULE__.__info__(:attributes), :queries, [])
      end
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
  
  defmacro command(name, definition_arg, code) do
    quote do
      command unquote(name), nil, unquote(definition_arg) do
        unquote(code)
      end
    end
  end

  defmacro command(name, parameter_name, definition_arg, code) do
    quote do
      defp unquote(name)(unquote(parameter_name), unquote(definition_arg)) do
        unquote(code)
      end

      def handle_cast({unquote(name), unquote(parameter_name)}, definition) do
        unquote(name)(unquote(parameter_name), definition)

        {:noreply, definition}
      end
    end
  end

  defmacro query(name, definition_arg, code) do
    quote do
      query unquote(name), nil, unquote(definition_arg) do
        unquote(code)
      end
    end
  end

  defmacro query(name, parameter_name, definition_arg, code) do
    quote do
      @queries [%{name: to_string(unquote(name))} | @queries]

      defp unquote(name)(unquote(parameter_name), unquote(definition_arg)) do
        unquote(code)
      end
      
      def handle_call({unquote(name), unquote(parameter_name)}, definition) do
        response = unquote(name)(unquote(parameter_name), definition)

        {:reply, response, definition}
      end
    end
  end
end
