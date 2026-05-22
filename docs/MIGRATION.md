# Migration

## From Direct WiFi Code

Move caller code behind `Mob.Wifi.bridge_module/0` and start the bridge with an
explicit `:event_target`. Outbound frames should go through
`Mob.Wifi.WifiBridge.send_frame/4`; inbound native events should be normalized
into `{:transport_up, peer_id, metadata}`, `{:frame, peer_id, frame}`, and
`{:transport_down, peer_id}` messages.

## From BLE Transport

`mob_wifi` follows the same policy shape as `mob_ble`: the package owns carrier
selection, validates configuration at startup, and rejects unsupported carriers
early.

The important difference is that WiFi has platform-specific carriers. Do not
expect a single native implementation to cover Android, iOS, and cross-platform
interop.

## Native Implementation Order

1. Android WiFi Direct native client.
2. iOS Multipeer native client.
3. Bonjour/TCP cross-platform discovery and socket transport.
4. Optional WiFi Aware candidate after hardware validation.
