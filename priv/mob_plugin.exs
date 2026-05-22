%{
  name: :mob_wifi,
  mob_version: "~> 0.5",
  plugin_spec_version: 1,
  description:
    "WiFi transport for mob with Android WiFi Direct, iOS Multipeer, and cross-platform Bonjour/TCP carrier policy.",
  carriers: [:wifi_direct, :multipeer, :bonjour_tcp],
  primary_carrier: :wifi_direct,
  wifi_direct: %{
    status: :phase_1_policy,
    platforms: [:android],
    android: %{
      api: "WifiP2pManager",
      manifest_permissions: [
        "android.permission.ACCESS_FINE_LOCATION",
        "android.permission.CHANGE_WIFI_STATE",
        "android.permission.ACCESS_WIFI_STATE",
        "android.permission.INTERNET",
        "android.permission.NEARBY_WIFI_DEVICES"
      ],
      native_dir: "priv/native/android"
    }
  },
  multipeer: %{
    status: :planned,
    platforms: [:ios],
    ios: %{
      frameworks: ["MultipeerConnectivity"],
      plist_keys: %{
        "NSLocalNetworkUsageDescription" =>
          "Required for nearby peer-to-peer messaging over WiFi"
      },
      native_dir: "priv/native/ios"
    }
  },
  bonjour_tcp: %{
    status: :planned,
    platforms: [:android, :ios],
    note:
      "Cross-platform discovery and transport path for Android/iOS interop. Requires hardware validation and topology decision."
  }
}
