defmodule AlfredServer do
  use GenServer
  
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end
  
  def find_available_plugins() do
    GenServer.call(__MODULE__, :find_plugin_types)
  end

  def add_plugin(type, parameters) do
    GenServer.cast(__MODULE__, {:add_plugin, {type, parameters}})
  end

  def discover_for(plugin_type) do
    GenServer.call(__MODULE__, {:discover_plugins, plugin_type})
  end

  def init(data) do
    {:ok, data}
  end

  def handle_call(:find_plugin_types, _, data) do
    response = AlfredServer.Plugins.Plugin.find_all_plugin_types()
    
    {:reply, response, data}
  end

  def handle_call({:discover_plugins, plugin_type}, _, data) do
    response = AlfredServer.Plugins.Plugin.discover_from(plugin_type)
    
    {:reply, response, data}
  end

  def handle_cast({:add_plugin, {type, parameters}}, data) do
    {:ok, plugin_id, plugin} = AlfredServer.Plugins.Plugin.initialize_plugin(type, parameters)
    #TODO: Add to data
    
    {:noreply, data}
  end
end
