defmodule Mob.Wifi.CarrierRejectedError do
  @moduledoc """
  Raised when a caller asks `Mob.Wifi` to use an unsupported or unvalidated carrier.
  """

  defexception [:carrier, :reason]

  @type t :: %__MODULE__{carrier: atom() | term(), reason: atom() | binary() | nil}

  @impl true
  def message(%__MODULE__{carrier: carrier, reason: reason}) do
    """
    Mob.Wifi: carrier #{inspect(carrier)} is rejected.

    Reason: #{inspect(reason || :unsupported_carrier)}
    Supported carriers are #{inspect(Mob.Wifi.Config.supported_carriers())}.
    Validated bridge carriers are #{inspect(Mob.Wifi.Config.validated_carriers())}.
    The primary carrier is #{inspect(Mob.Wifi.carrier())}.
    """
  end
end
