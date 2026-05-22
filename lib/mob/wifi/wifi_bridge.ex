defmodule Mob.Wifi.WifiBridge do
  @moduledoc """
  Initial WiFi bridge process for `mob_wifi`.

  The bridge establishes the lifecycle and event contract before native WiFi
  code lands. It validates carrier policy at startup and accepts an injected
  native client for tests or future platform adapters.
  """

  use GenServer

  if Code.ensure_loaded?(Mob.Transport) do
    @behaviour Mob.Transport
  end

  alias Mob.Wifi.{Error, Telemetry}

  @default_max_frame_bytes 256 * 1024

  @type native_client :: module()
  @type state :: %{
          event_target: pid(),
          config: keyword() | map(),
          carrier: atom(),
          native_client: native_client() | nil,
          max_frame_bytes: pos_integer()
        }

  def start_link(opts) do
    with :ok <- require_event_target(opts),
         :ok <- validate_start_config(opts) do
      GenServer.start_link(__MODULE__, opts)
    end
  end

  @doc "Sends a binary frame to a peer through the configured native client."
  @spec send_frame(GenServer.server(), term(), binary(), keyword()) :: :ok | {:error, term()}
  def send_frame(bridge, peer_id, frame, opts \\ []) when is_binary(frame) do
    GenServer.call(bridge, {:send_frame, peer_id, frame, opts})
  end

  @doc "Injects a native event into the bridge."
  @spec receive_native_event(GenServer.server(), map() | tuple()) :: :ok | {:error, term()}
  def receive_native_event(bridge, event) do
    GenServer.call(bridge, {:receive_native_event, event})
  end

  def stop(bridge), do: GenServer.stop(bridge)

  @impl true
  def init(opts) do
    config = Keyword.get(opts, :config, Application.get_env(:mob_wifi, :config, []))

    state = %{
      event_target: Keyword.fetch!(opts, :event_target),
      config: config,
      carrier: Keyword.get(opts, :carrier, config_value(config, :carrier)) || Mob.Wifi.carrier(),
      native_client: Keyword.get(opts, :native_client),
      max_frame_bytes:
        Keyword.get(opts, :max_frame_bytes, config_value(config, :max_frame_bytes)) ||
          @default_max_frame_bytes
    }

    Telemetry.execute_many(
      [[:mob_wifi, :bridge, :start], [:mob_wifi, :bridge, :started]],
      %{system_time: System.system_time()},
      %{
        carrier: state.carrier,
        max_frame_bytes: state.max_frame_bytes
      }
    )

    {:ok, state}
  end

  @impl true
  def terminate(reason, state) do
    Telemetry.execute_many(
      [[:mob_wifi, :bridge, :stop], [:mob_wifi, :bridge, :stopped]],
      %{system_time: System.system_time()},
      %{
        carrier: state.carrier,
        reason: reason
      }
    )

    :ok
  end

  @impl true
  def handle_call({:send_frame, peer_id, frame, opts}, _from, state) do
    reply =
      with :ok <- check_frame_size(frame, state.max_frame_bytes) do
        send_native(state.native_client, peer_id, frame, opts)
      end

    emit_send_telemetry(reply, peer_id, frame, state)

    {:reply, reply, state}
  end

  def handle_call({:receive_native_event, event}, _from, state) do
    reply = emit_event(event, state.event_target)
    {:reply, reply, state}
  end

  defp require_event_target(opts) do
    case Keyword.fetch(opts, :event_target) do
      {:ok, pid} when is_pid(pid) -> :ok
      {:ok, other} -> {:error, {:invalid_event_target, other}}
      :error -> {:error, {:missing_required_option, :event_target}}
    end
  end

  defp validate_start_config(opts) do
    config = Keyword.get(opts, :config, Application.get_env(:mob_wifi, :config, []))

    case Mob.Wifi.validate_config(config) do
      :ok -> validate_bridge_carrier!(Keyword.get(opts, :carrier, config_value(config, :carrier)))
      err -> raise "mob_wifi validate_config failed: #{inspect(err)}"
    end
  end

  defp validate_bridge_carrier!(nil), do: :ok
  defp validate_bridge_carrier!(:wifi_direct), do: :ok

  defp validate_bridge_carrier!(carrier) when carrier in [:multipeer, :bonjour_tcp] do
    raise Mob.Wifi.CarrierRejectedError,
      carrier: carrier,
      reason: :carrier_not_yet_implemented_by_bridge
  end

  defp validate_bridge_carrier!(carrier) do
    raise Mob.Wifi.CarrierRejectedError,
      carrier: carrier,
      reason: :unsupported_carrier
  end

  defp config_value(config, key) when is_list(config), do: Keyword.get(config, key)
  defp config_value(config, key) when is_map(config), do: Map.get(config, key)
  defp config_value(_config, _key), do: nil

  defp check_frame_size(frame, max_frame_bytes) when byte_size(frame) <= max_frame_bytes, do: :ok

  defp check_frame_size(frame, max_frame_bytes) do
    {:error, {:frame_too_large, byte_size(frame), max_frame_bytes}}
  end

  defp send_native(nil, _peer_id, _frame, _opts), do: {:error, :native_client_not_configured}

  defp send_native(client, peer_id, frame, opts) do
    client.send_frame(peer_id, frame, opts)
  end

  defp emit_event({:peer_up, peer_id, metadata}, event_target) when is_map(metadata) do
    Telemetry.execute([:mob_wifi, :peer, :discovered], %{count: 1}, %{
      carrier: carrier(metadata),
      peer_id: to_string(peer_id)
    })

    Telemetry.execute([:mob_wifi, :peer, :up], %{count: 1}, %{peer_id: to_string(peer_id)})
    send(event_target, {:transport_up, to_string(peer_id), metadata})
    :ok
  end

  defp emit_event({:peer_down, peer_id}, event_target) do
    Telemetry.execute([:mob_wifi, :peer, :down], %{count: 1}, %{peer_id: to_string(peer_id)})
    send(event_target, {:transport_down, to_string(peer_id)})
    :ok
  end

  defp emit_event({:frame, peer_id, frame}, event_target) when is_binary(frame) do
    Telemetry.execute([:mob_wifi, :frame, :received], %{bytes: byte_size(frame)}, %{
      peer_id: to_string(peer_id)
    })

    send(event_target, {:frame, to_string(peer_id), frame})
    :ok
  end

  defp emit_event(%{"type" => "peer_up", "peer_id" => peer_id} = event, event_target) do
    metadata = Map.get(event, "metadata", %{})
    emit_event({:peer_up, peer_id, normalize_metadata(metadata)}, event_target)
  end

  defp emit_event(%{"type" => "peer_down", "peer_id" => peer_id}, event_target) do
    emit_event({:peer_down, peer_id}, event_target)
  end

  defp emit_event(%{"type" => "frame", "peer_id" => peer_id, "frame" => frame}, event_target)
       when is_binary(frame) do
    emit_event({:frame, peer_id, frame}, event_target)
  end

  defp emit_event(event, event_target) do
    reason = {:unknown_native_event, event}
    error = Error.new(reason, details: %{event: event})
    Telemetry.execute([:mob_wifi, :bridge, :error], %{count: 1}, %{reason: reason, error: error})
    send(event_target, {:transport_error, reason})
    {:error, reason}
  end

  defp emit_send_telemetry(:ok, peer_id, frame, state) do
    Telemetry.execute([:mob_wifi, :frame, :sent], %{bytes: byte_size(frame)}, %{
      carrier: state.carrier,
      peer_id: to_string(peer_id)
    })
  end

  defp emit_send_telemetry({:error, reason}, peer_id, frame, state) do
    error = Error.new(reason, carrier: state.carrier, peer_id: peer_id)

    Telemetry.execute([:mob_wifi, :frame, :send_error], %{bytes: byte_size(frame)}, %{
      carrier: state.carrier,
      error: error,
      peer_id: to_string(peer_id),
      reason: reason
    })
  end

  defp carrier(%{"carrier" => "wifi_direct"}), do: :wifi_direct
  defp carrier(%{"carrier" => "multipeer"}), do: :multipeer
  defp carrier(%{"carrier" => "bonjour_tcp"}), do: :bonjour_tcp
  defp carrier(%{carrier: carrier}) when is_atom(carrier), do: carrier
  defp carrier(_metadata), do: nil

  defp normalize_metadata(metadata) when is_map(metadata), do: metadata
  defp normalize_metadata(_metadata), do: %{}
end
