defmodule Mob.Wifi.Telemetry do
  @moduledoc """
  Telemetry event helpers for `mob_wifi`.

  The package intentionally emits low-cardinality metadata. Peer identifiers
  are included only where they are already part of the transport event.
  """

  @doc false
  @spec execute([atom()], map(), map()) :: :ok
  def execute(event, measurements, metadata \\ %{}) do
    if Code.ensure_loaded?(:telemetry) and function_exported?(:telemetry, :execute, 3) do
      :telemetry.execute(event, measurements, metadata)
    end

    :ok
  end
end
