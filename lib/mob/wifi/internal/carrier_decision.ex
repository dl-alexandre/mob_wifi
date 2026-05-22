defmodule Mob.Wifi.Internal.CarrierDecision do
  @moduledoc false

  @doc "Returns a stable summary of the current carrier decision."
  @spec summary() :: map()
  def summary do
    %{
      primary_carrier: :wifi_direct,
      bridge_status: :skeleton,
      validated_carriers: Mob.Wifi.Config.validated_carriers(),
      recognized_carriers: Mob.Wifi.Config.supported_carriers(),
      platform_strategy: %{
        android: [:wifi_direct, :wifi_aware_later],
        ios: [:multipeer],
        cross_platform: [:bonjour_tcp]
      },
      evidence_required: [
        :android_android_wifi_direct,
        :ios_ios_multipeer,
        :android_ios_bonjour_tcp,
        :battery_and_background_behavior,
        :frame_size_and_reconnect_behavior
      ]
    }
  end
end
