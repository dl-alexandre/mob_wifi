defmodule Mob.Wifi.Config do
  @moduledoc """
  Configuration validation for `mob_wifi`.
  """

  @supported_carriers [:wifi_direct, :multipeer, :bonjour_tcp]
  @validated_carriers [:wifi_direct]
  @platforms [:android, :ios]
  @evidence_modes [:production, :diagnostic]

  @doc "Returns carriers recognized by the plugin manifest."
  @spec supported_carriers() :: [:wifi_direct | :multipeer | :bonjour_tcp]
  def supported_carriers, do: @supported_carriers

  @doc "Returns carriers allowed for bridge startup without explicit diagnostic mode."
  @spec validated_carriers() :: [:wifi_direct]
  def validated_carriers, do: @validated_carriers

  @doc false
  @spec validate(keyword() | map()) :: :ok | {:error, term()}
  def validate(config) do
    cfg = Map.new(Enum.to_list(config))

    with :ok <- check_carrier(cfg),
         :ok <- check_platform(cfg),
         :ok <- check_evidence_mode(cfg),
         :ok <- check_max_frame_bytes(cfg),
         :ok <- check_discovery(cfg),
         :ok <- check_log_level(cfg) do
      check_native(cfg)
    end
  end

  defp check_carrier(%{carrier: carrier}) when carrier in @supported_carriers, do: :ok

  defp check_carrier(%{carrier: carrier}) do
    raise Mob.Wifi.CarrierRejectedError,
      carrier: carrier,
      reason: :unsupported_carrier
  end

  defp check_carrier(_cfg), do: :ok

  defp check_platform(%{platform: platform}) when platform in @platforms, do: :ok
  defp check_platform(%{platform: platform}), do: {:error, {:invalid_config, :platform, platform}}
  defp check_platform(_cfg), do: :ok

  defp check_evidence_mode(%{evidence_mode: mode}) when mode in @evidence_modes, do: :ok

  defp check_evidence_mode(%{evidence_mode: mode}) do
    {:error, {:invalid_config, :evidence_mode, mode}}
  end

  defp check_evidence_mode(_cfg), do: :ok

  defp check_max_frame_bytes(%{max_frame_bytes: bytes}) when is_integer(bytes) and bytes > 0 do
    :ok
  end

  defp check_max_frame_bytes(%{max_frame_bytes: bytes}) do
    {:error, {:invalid_config, :max_frame_bytes, bytes}}
  end

  defp check_max_frame_bytes(_cfg), do: :ok

  defp check_discovery(%{discovery: discovery}) when discovery in [:native, :bonjour, :manual] do
    :ok
  end

  defp check_discovery(%{discovery: discovery}) do
    {:error, {:invalid_config, :discovery, discovery}}
  end

  defp check_discovery(_cfg), do: :ok

  defp check_log_level(%{log_level: level}) when is_atom(level), do: :ok
  defp check_log_level(%{log_level: level}), do: {:error, {:invalid_config, :log_level, level}}
  defp check_log_level(_cfg), do: :ok

  defp check_native(%{native?: native?}) when is_boolean(native?), do: :ok
  defp check_native(%{native?: native?}), do: {:error, {:invalid_config, :native?, native?}}
  defp check_native(_cfg), do: :ok
end
