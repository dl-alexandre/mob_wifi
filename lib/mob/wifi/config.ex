defmodule Mob.Wifi.Config do
  @moduledoc """
  Configuration validation for `mob_wifi`.
  """

  @supported_carriers [:wifi_direct, :multipeer, :bonjour_tcp]
  @validated_carriers [:wifi_direct]
  @platforms [:android, :ios]
  @modes [:production, :test, :simulation]
  @discovery_modes [:native, :bonjour, :manual]

  @schema [
    carrier: [
      type: {:in, @supported_carriers},
      doc: "WiFi carrier requested by deployment configuration."
    ],
    platform: [
      type: {:in, @platforms},
      doc: "Host mobile platform."
    ],
    mode: [
      type: {:in, @modes},
      default: :production,
      doc: "Runtime strictness mode: :production, :test, or :simulation."
    ],
    evidence_mode: [
      type: {:in, [:production, :diagnostic]},
      doc: "Deprecated alias for :mode. :diagnostic maps to :test."
    ],
    max_frame_bytes: [
      type: :pos_integer,
      default: 256 * 1024,
      doc: "Maximum binary frame size accepted by the bridge."
    ],
    discovery: [
      type: {:in, @discovery_modes},
      default: :native,
      doc: "Discovery path used by the carrier adapter."
    ],
    log_level: [
      type: :atom,
      default: :info,
      doc: "Logger level used by host integrations."
    ],
    native?: [
      type: :boolean,
      default: true,
      doc: "Whether native carrier code is expected to be available."
    ]
  ]

  @doc "Returns carriers recognized by the plugin manifest."
  @spec supported_carriers() :: [:wifi_direct | :multipeer | :bonjour_tcp]
  def supported_carriers, do: @supported_carriers

  @doc "Returns carriers allowed for bridge startup without explicit diagnostic mode."
  @spec validated_carriers() :: [:wifi_direct]
  def validated_carriers, do: @validated_carriers

  @doc "Returns the validation schema used for deployment configuration."
  @spec schema() :: keyword()
  def schema, do: @schema

  @doc """
  Validates deployment configuration.

  Unknown keys are tolerated for forward compatibility. Unsupported carrier
  values still raise `Mob.Wifi.CarrierRejectedError` to preserve the strict
  policy contract used by plugin activation.
  """
  @spec validate(keyword() | map()) :: :ok | {:error, term()}
  def validate(config) do
    config
    |> normalize_config()
    |> validate_options()
  end

  defp normalize_config(config) do
    config
    |> Enum.to_list()
    |> Keyword.new()
    |> normalize_mode_alias()
  end

  defp normalize_mode_alias(config) do
    case Keyword.fetch(config, :evidence_mode) do
      {:ok, :diagnostic} ->
        config
        |> Keyword.put_new(:mode, :test)
        |> Keyword.delete(:evidence_mode)

      {:ok, :production} ->
        config
        |> Keyword.put_new(:mode, :production)
        |> Keyword.delete(:evidence_mode)

      :error ->
        config

      {:ok, other} ->
        Keyword.put(config, :evidence_mode, other)
    end
  end

  defp validate_options(config) do
    case NimbleOptions.validate(config, @schema) do
      {:ok, _validated} ->
        :ok

      {:error, error} when is_exception(error, NimbleOptions.ValidationError) ->
        case error.key do
          :carrier ->
            raise Mob.Wifi.CarrierRejectedError,
              carrier: error.value,
              reason: :unsupported_carrier

          key ->
            {:error, {:invalid_config, key, error.value}}
        end

      {:error, other} ->
        {:error, other}
    end
  end
end
