defmodule AlfredServer.Plugins.Plugin do
  @callback start_discover() :: :ok
  
  defmodule Definition do
    defstruct type: nil,
              id: nil,
              name: nil,
              settings: %{}
  end

  def find_all_plugin_types() do
    available_modules(AlfredServer.Plugins.Plugin) |> Enum.reduce([], &load_plugin/2)
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
    unless Module.defines?(env.module, {:start_discover, 0}) do
      quote do
        def start_discover() do
          :ok
        end

        defoverridable start_discover: 0
      end
    end

    unless Module.defines?(env.module, {:init, 1}) do
      quote do
        def init(definition) do
          {:ok, definition}
        end

        defoverridable init: 1
      end
    end
  end
end
