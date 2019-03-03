defmodule AlfredServer.Plugins.Plugin do
  @moduledoc false

  @callback discover() :: []
  @callback initialize(data) :: :ok when data: Any

  def find_all_plugin_types() do
    []
  end

  def discover_from(plugin_type) do
    String.to_existing_atom("Elixir.#{plugin_type}.discover")()
  end

  def initialize_plugin(plugin_type, parameters) do
    plugin_id = UUID.uuid4()
    
    GenServer.start_link(
      String.to_existing_atom("Elixir.#{plugin_type}"),
      parameters,
      name: {:global, plugin_id}
    )

    {:ok, plugin_id}
  end
  
  defmacro __using__(_) do
    quote location: :keep do
      use GenServer
      @behaviour AlfredServer.Plugins.Plugin
      
      def init(data) do
        GenServer.cast(self(), :init)
        
        {:ok, data}
      end
      
      def handle_cast(:init, data) do
        initialize(data)

        {:noreply, data}
      end
      
      def handle_cast({:execute, command, parameters}, data) do
        String.to_existing_atom(command)(parameters)
        
        {:noreply, data}
      end
      
      def handle_call({:query, query, parameters}, data) do
        response = String.to_existing_atom(query)(parameters)
        
        {:reply, response, data}
      end
    end
  end

  defmacro __before_compile__(env) do
    unless Module.defines?(env.module, {:discover, 0}) do
      quote do
        @doc false
        def discover() do
          []
        end

        defoverridable discover: 0
      end
    end

    unless Module.defines?(env.module, {:initialize, 1}) do
      quote do
        @doc false
        def initialize(_) do
          :ok
        end

        defoverridable initialize: 1
      end
    end
  end
end
