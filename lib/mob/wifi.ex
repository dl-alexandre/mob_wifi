defmodule Mob.Wifi do
  @moduledoc """
  WiFi transport plugin for `mob`.

  `mob_wifi` owns the WiFi carrier decision for phone-to-phone transports.
  The initial package is intentionally policy-first: Android WiFi Direct,
  iOS Multipeer Connectivity, and cross-platform Bonjour/TCP are recognized
  as distinct carriers because they have different platform constraints and
  validation requirements.
  """

  alias Mob.Wifi.Config

  # Structurally implements the Mob.Transport contract (start_link/1, send_frame/4,
  # optional stop/1). The behaviour is intentionally not declared via @behaviour so
  # this package stays self-contained and standalone-publishable; Mob.Transport.Adapter
  # verifies the callbacks with function_exported?/3 at runtime.

  @doc "Returns the active primary carrier for the first bridge implementation."
  @spec carrier() :: :wifi_direct
  def carrier, do: :wifi_direct

  @doc "Returns the transport implementation module for plugin activation."
  @spec bridge_module() :: module()
  def bridge_module, do: Mob.Wifi.WifiBridge

  @doc "Transitional alias for `bridge_module/0`."
  @spec default_bridge() :: module()
  def default_bridge, do: bridge_module()

  @doc "Returns the transport adapter module for this plugin (the public face implementing Mob.Transport)."
  @spec transport_module() :: module()
  def transport_module, do: __MODULE__

  @doc """
  Validates deployment configuration.

  Unknown keys are tolerated for forward compatibility. Unsupported carriers
  raise `Mob.Wifi.CarrierRejectedError` so carrier drift fails at startup.
  """
  @spec validate_config(keyword() | map()) :: :ok | {:error, term()}
  def validate_config(config) when is_list(config) or is_map(config) do
    Config.validate(config)
  end

  # Mob.Transport behaviour implementation. Required callbacks (start_link/1,
  # send_frame/4) plus optional stop/1 are delegated to the internal
  # bridge_module() (WifiBridge GenServer). Optional broadcast_frame/3 is not
  # implemented; the adapter reports :broadcast_not_supported. capabilities/0,
  # metadata/0, and peers/1 are plain plugin helpers, not behaviour callbacks.

  def start_link(opts), do: bridge_module().start_link(opts)

  def stop(transport), do: bridge_module().stop(transport)

  def send_frame(transport, peer_id, frame, opts),
    do: bridge_module().send_frame(transport, peer_id, frame, opts)

  @doc "Known peers, delegated to the internal bridge."
  def peers(transport), do: bridge_module().peers(transport)

  @doc "Transport capabilities advertised by this plugin."
  def capabilities, do: [:wifi]

  @doc "Static transport metadata, delegated to the internal bridge."
  def metadata, do: bridge_module().metadata()
end
