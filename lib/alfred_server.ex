defmodule AlfredServer do
  use GenServer
  
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end
  
  def add_plugin(definition) do
    GenServer.cast(__MODULE__, {:add_plugin, definition})
  end

  def init(_) do
    Mdns.Client.start()

    AlfredServer.Plugins.Plugin.find_all_plugin_types()
    |> Enum.each(fn (plugin_type) ->
      AlfredServer.Plugins.Plugin.start_discover_from(plugin_type)
    end)
    
    {:ok, %{}}
  end

  def handle_cast({:add_plugin, definition}, plugins) do
    {:ok, plugin} = AlfredServer.Plugins.Plugin.initialize_plugin(definition)

    {:noreply, Map.put(plugins, definition.id, %{pid: plugin, definition: definition})}
  end
end
