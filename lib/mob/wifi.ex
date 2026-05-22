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

  @doc "Returns the active primary carrier for the first bridge implementation."
  @spec carrier() :: :wifi_direct
  def carrier, do: :wifi_direct

  @doc "Returns the transport implementation module for plugin activation."
  @spec bridge_module() :: module()
  def bridge_module, do: Mob.Wifi.WifiBridge

  @doc "Transitional alias for `bridge_module/0`."
  @spec default_bridge() :: module()
  def default_bridge, do: bridge_module()

  @doc """
  Validates deployment configuration.

  Unknown keys are tolerated for forward compatibility. Unsupported carriers
  raise `Mob.Wifi.CarrierRejectedError` so carrier drift fails at startup.
  """
  @spec validate_config(keyword() | map()) :: :ok | {:error, term()}
  def validate_config(config) when is_list(config) or is_map(config) do
    Config.validate(config)
  end
end
