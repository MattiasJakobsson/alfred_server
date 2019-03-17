defmodule Alfred.Engine do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def add_plugin(definition) do
    GenServer.cast(__MODULE__, {:add_plugin, definition})
  end

  def add_workflow(triggers, definition) do
    GenServer.cast(__MODULE__, {:add_workflow, {triggers, definition}})
  end

  def init(_) do
    migrate_database()
    
    initialize_plugins()

    initialize_workflows()

    GenServer.cast(self(), :start_plugin_discovery)

    Mdns.Client.start()

    {:ok, %{}}
  end

  defp migrate_database() do
    :mnesia.create_schema([node()])
    :mnesia.start
    
    :mnesia.create_table(Plugin, [attributes: [:id, :definition]])
    :mnesia.create_table(Workflow, [attributes: [:id, :triggers, :definition]])
    
    :ok
  end

  defp initialize_plugins() do
    {:atomic, plugins} = :mnesia.transaction(fn ->
      :mnesia.match_object({Plugin, :_, :_})
    end)

    me = self()

    plugins
    |> Enum.each(fn ({_, definition}) ->
      {:ok, parsed_plugin} = Poison.Parser.parse(definition)

      GenServer.cast(me, {:start_plugin, parsed_plugin})
    end)
  end

  defp initialize_workflows() do
    {:atomic, workflows} = :mnesia.transaction(fn ->
      :mnesia.match_object({Workflow, :_, :_, :_})
    end)

    me = self()

    workflows
    |> Enum.each(fn ({_, triggers, definition}) ->
      GenServer.cast(me, {:start_workflow, {triggers, definition}})
    end)
  end

  def handle_cast({:add_plugin, definition}, plugins) do
    :mnesia.transaction(fn -> 
      :mnesia.write({Plugin, definition.id, Poison.encode!(definition, [])})
    end)

    handle_cast({:start_plugin, definition}, plugins)
  end

  def handle_cast({:start_plugin, definition}, plugins) do
    {:ok, plugin} = Alfred.Plugins.Plugin.initialize_plugin(definition)

    {:noreply, Map.put(plugins, definition.id, %{pid: plugin, definition: definition})}
  end

  def handle_cast({:add_workflow, {triggers, definition}}, plugins) do
    :mnesia.transaction(fn ->
      :mnesia.write({Workflow, UUID.uuid4(), Poison.encode!(triggers, []), Poison.encode!(definition, [])})
    end)

    handle_cast({:start_workflow, {triggers, definition}}, plugins)
  end

  def handle_cast({:start_workflow, {triggers, definition}}, plugins) do
    Traverse.Engine.schedule_workflow(triggers, definition)

    {:noreply, plugins}
  end

  def handle_cast(:start_plugin_discovery, plugins) do
    Traverse.PluginLoader.find_all_plugin_types(Alfred.Plugins.Plugin)
    |> Enum.each(fn (plugin_type) ->
      Alfred.Plugins.Plugin.start_discover_from(plugin_type)
    end)

    {:noreply, plugins}
  end
end
