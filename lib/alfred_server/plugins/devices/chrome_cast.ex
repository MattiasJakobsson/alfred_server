defmodule AlfredServer.Plugins.Devices.ChromeCast do
  use AlfredServer.Plugins.Plugin

  def start_discover() do
    {:ok, _} = AlfredServer.Plugins.Devices.ChromeCast.Discoverer.start_link()
    
    :ok
  end

  def init(definition) do
    {:ok, chromecast} = Chromecast.start_link(definition.settings.ip)
    
    state = Chromecast.state(chromecast)

    Process.send_after(self(), :update_status, 5_000)
    
    {:ok, {chromecast, state}}
  end

  def handle_info(:update_status, {chromecast, _}) do
    Process.send_after(self(), :update_status, 5_000)
    
    new_state = Chromecast.state(chromecast)
    
    {:noreply, {chromecast, new_state}}
  end

  def handle_call(:status, _, {chromecast, state}) do
    {:reply, state, {chromecast, state}}
  end
  
  defmodule Discoverer do
    use GenServer

    def start_link() do
      GenServer.start_link(__MODULE__, [], name: __MODULE__)
    end
    
    def init() do
      Mdns.Client.query("_googlecast._tcp.local")
      
      Process.send(self(), :update_devicelist, [])
      
      {:ok, %{}}
    end
    
    def handle_info(:update_devicelist, devices) do
      current_devices = Mdns.Client.devices()

      new_devices = Map.get(current_devices, :"_googlecast._tcp.local", [])
      |> Enum.filter(fn(cast) -> Map.has_key?(cast.payload, "md") end)
      |> Enum.filter(fn(cast) -> !Map.has_key?(devices, get_cast_key(cast)) end)
      |> Enum.reduce(devices, fn (cast, device_map) ->
        definition = %AlfredServer.Plugins.Plugin.Definition{
          type: AlfredServer.Plugins.Devices.ChromeCast,
          id: get_cast_key(cast),
          name: Map.get(cast.payload, "fn", "Chromecast"),
          settings: %{ip: cast.ip}
        }
      
        #TODO: Publish event about new plugin
        #GenServer.cast(listener, {:plugin_discovered, definition})

        Map.put(device_map, get_cast_key(cast), cast.payload)
      end)

      Process.send_after(self(), :update_devicelist, 10_000)
      
      {:noreply, new_devices}
    end

    defp get_cast_key(cast) do
      ip = cast.ip |> Tuple.to_list |> Enum.map(fn item -> item |> to_string end) |> Enum.join(".")
      
      type_name = Map.get(cast.payload, "md", "")
      |> String.replace(" ", "_")
      |> String.downcase()
      
      "#{type_name}_#{ip}"
    end
  end
end
