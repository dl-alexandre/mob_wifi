defmodule Mob.Wifi.Carrier do
  @moduledoc """
  Behaviour for WiFi carrier adapters.

  Carrier modules own platform-specific discovery and frame delivery. The
  bridge owns Mob-facing lifecycle, policy validation, telemetry, and event
  normalization.
  """

  @typedoc "Carrier runtime option list."
  @type opts :: keyword()

  @typedoc "Opaque carrier process or native resource handle."
  @type handle :: pid() | reference() | term()

  @typedoc "Peer identifier used by Mob transport events."
  @type peer_id :: String.t()

  @typedoc "Carrier event emitted to `Mob.Wifi.WifiBridge.receive_native_event/2`."
  @type event ::
          {:peer_up, peer_id(), map()}
          | {:peer_down, peer_id()}
          | {:frame, peer_id(), binary()}
          | map()

  @callback start_link(opts()) :: GenServer.on_start()
  @callback send_frame(handle(), peer_id(), binary(), opts()) :: :ok | {:error, term()}
  @callback discover_peers(handle(), opts()) :: :ok | {:error, term()}
  @callback stop(handle()) :: :ok | {:error, term()}
end
