defmodule Mob.Wifi.Diagnostics do
  @moduledoc """
  Read-only diagnostics for the WiFi carrier decision.
  """

  alias Mob.Wifi.Internal.CarrierDecision

  @doc "Returns the current carrier policy summary."
  @spec carrier_policy() :: map()
  def carrier_policy, do: CarrierDecision.summary()
end
