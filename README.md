# mob_wifi

`mob_wifi` is the WiFi transport plugin for `mob`.

The first version establishes the package, plugin manifest, carrier policy,
configuration validation, and bridge lifecycle. Native Android and iOS code is
intentionally deferred until the hardware validation matrix confirms the final
carrier split.

## Carrier Policy

- Android primary: WiFi Direct through `WifiP2pManager`.
- iOS primary: Multipeer Connectivity for iOS-to-iOS sessions.
- Cross-platform candidate: Bonjour/mDNS discovery plus TCP/UDP transport.

`Mob.Wifi.WifiBridge` only starts with `:wifi_direct` today. Other recognized
carriers are documented and accepted at manifest/config level, but rejected by
the bridge until native implementations exist.

## Usage

```elixir
config :mob_wifi, config: [
  carrier: :wifi_direct,
  platform: :android,
  evidence_mode: :production,
  max_frame_bytes: 262_144
]
```

```elixir
{:ok, bridge} =
  Mob.Wifi.bridge_module().start_link(
    event_target: self(),
    native_client: MyNativeWifiClient
  )

:ok = Mob.Wifi.WifiBridge.send_frame(bridge, "peer-1", <<1, 2, 3>>)
```

## Validation

```bash
mix test apps/mob_wifi
```
