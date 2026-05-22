defmodule Mob.Wifi.Error do
  @moduledoc """
  Structured WiFi transport error metadata.

  Public bridge APIs still return the established `{:error, reason}` tuples.
  This struct gives telemetry, docs, and future carrier adapters a stable shape
  for richer error context without changing those return values.
  """

  @enforce_keys [:reason]
  defstruct [:reason, :carrier, :peer_id, :details]

  @type t :: %__MODULE__{
          reason: atom() | tuple(),
          carrier: atom() | nil,
          peer_id: String.t() | nil,
          details: map() | nil
        }

  @doc "Builds structured error metadata from a reason and optional context."
  @spec new(atom() | tuple(), keyword()) :: t()
  def new(reason, opts \\ []) do
    %__MODULE__{
      reason: reason,
      carrier: Keyword.get(opts, :carrier),
      peer_id: peer_id(Keyword.get(opts, :peer_id)),
      details: Keyword.get(opts, :details)
    }
  end

  defp peer_id(nil), do: nil
  defp peer_id(peer_id), do: to_string(peer_id)
end
