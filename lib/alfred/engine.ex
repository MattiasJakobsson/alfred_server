defmodule Alfred.Engine do
  use GenServer
  import Ecto.Query

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
    initialize_plugins()

    initialize_workflows()

    GenServer.cast(self(), :start_plugin_discovery)

    Mdns.Client.start()

    {:ok, %{}}
  end

  defp initialize_plugins() do
    query = from(p in Alfred.Entities.Plugin, select: p)

    plugins = Alfred.Entities.Plugin.Repo.all(query)

    me = self()

    plugins
    |> Enum.each(fn (plugin) ->
      {:ok, parsed_plugin} = Poison.Parser.parse(plugin.definition)

      GenServer.cast(me, {:start_plugin, parsed_plugin})
    end)
  end

  defp initialize_workflows() do
    query = from(w in Alfred.Entities.Workflow, select: w)

    workflows = Alfred.Entities.Workflow.Repo.all(query)

    me = self()

    workflows
    |> Enum.each(fn (workflow) ->
      GenServer.cast(me, {:start_workflow, {workflow.triggers, workflow.definition}})
    end)
  end

  def handle_cast({:add_plugin, definition}, plugins) do
    Alfred.Entities.Plugin.Repo.insert(%Alfred.Entities.Plugin{key: definition.id, definition: Poison.encode!(definition, [])})

    handle_cast({:start_plugin, definition}, plugins)
  end

  def handle_cast({:start_plugin, definition}, plugins) do
    {:ok, plugin} = Alfred.Plugins.Plugin.initialize_plugin(definition)

    {:noreply, Map.put(plugins, definition.id, %{pid: plugin, definition: definition})}
  end

  def handle_cast({:add_workflow, {triggers, definition}}, plugins) do
    Alfred.Entities.Workflow.Repo.insert(%Alfred.Entities.Workflow{triggers: Poison.encode!(triggers, []), definition: Poison.encode!(definition, [])})

    handle_cast({:start_workflow, {triggers, definition}}, plugins)
  end

  def handle_cast({:start_workflow, {triggers, definition}}, plugins) do
    Traverse.Engine.schedule_workflow(triggers, definition)

    {:noreply, plugins}
  end

  def handle_cast(:start_plugin_discovery, plugins) do
    Alfred.Plugins.Plugin.find_all_plugin_types()
    |> Enum.each(fn (plugin_type) ->
      Alfred.Plugins.Plugin.start_discover_from(plugin_type)
    end)

    {:noreply, plugins}
  end
end