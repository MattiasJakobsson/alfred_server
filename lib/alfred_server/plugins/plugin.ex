defmodule AlfredServer.Plugins.Plugin do
  @callback discover() :: [] | [plugin] when plugin: Any

  def find_all_plugin_types() do
    available_modules(AlfredServer.Plugins.Plugin) |> Enum.reduce([], &load_plugin/2)
  end

  def discover_from(plugin_type) when is_binary(plugin_type) do
    discover_from(String.to_existing_atom("Elixir.#{plugin_type}"))
  end

  def discover_from(plugin_type) when is_atom(plugin_type) do
    apply(plugin_type, :discover, [])
  end

  def initialize_plugin(plugin_type, parameters) when is_binary(plugin_type) do
    initialize_plugin(String.to_existing_atom("Elixir.#{plugin_type}"), parameters)
  end

  def initialize_plugin(plugin_type, parameters) when is_atom(plugin_type) do
    plugin_id = UUID.uuid4()

    {:ok, plugin} = GenServer.start_link(
      plugin_type,
      parameters,
      name: {:global, plugin_id}
    )

    {:ok, plugin_id, plugin}
  end

  defp load_plugin(module, modules) do
    if Code.ensure_loaded?(module), do: [module | modules], else: modules
  end

  defp available_modules(plugin_type) do
    Mix.Task.run("loadpaths", [])
    
    Path.wildcard(Path.join([Mix.Project.build_path, "**/ebin/**/*.beam"]))
    |> Stream.map(fn path ->
      {:ok, {mod, chunks}} = :beam_lib.chunks('#{path}', [:attributes])
      {mod, get_in(chunks, [:attributes, :behaviour])}
    end)
    |> Stream.filter(fn {_mod, behaviours} -> is_list(behaviours) && plugin_type in behaviours end)
    |> Enum.uniq
    |> Enum.map(fn {module, _} -> module end)
  end
  
  defmacro __using__(_) do
    quote location: :keep do
      use GenServer
      @behaviour AlfredServer.Plugins.Plugin
    end
  end

  defmacro __before_compile__(env) do
    unless Module.defines?(env.module, {:discover, 0}) do
      quote do
        def discover() do
          []
        end

        defoverridable discover: 0
      end
    end

    unless Module.defines?(env.module, {:init, 1}) do
      quote do
        def init(data) do
          {:ok, data}
        end

        defoverridable init: 1
      end
    end
  end
end
