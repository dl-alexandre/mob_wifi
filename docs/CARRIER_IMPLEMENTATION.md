# Carrier Implementation Guide

Carrier modules implement `Mob.Wifi.Carrier` and keep platform-specific work
outside `Mob.Wifi.WifiBridge`.

## Contract

- `start_link/1` starts the carrier adapter or native owner.
- `send_frame/4` sends a binary frame to a peer.
- `discover_peers/2` begins or refreshes discovery.
- `stop/1` releases platform resources.

Native adapters should report inbound state through
`Mob.Wifi.WifiBridge.receive_native_event/2` using one of these shapes:

```elixir
{:peer_up, "peer-id", %{"carrier" => "wifi_direct"}}
{:frame, "peer-id", <<1, 2, 3>>}
{:peer_down, "peer-id"}
```

Unknown events are reported to the bridge's `event_target` as
`{:transport_error, reason}`.

## Carrier Boundaries

Android WiFi Direct, iOS Multipeer Connectivity, and Bonjour/TCP should be
implemented as separate adapters. They have different permission models,
discovery semantics, trust assumptions, and background behavior.

## Native Resource Cleanup

Each adapter must make `stop/1` idempotent and release discovery sessions,
sockets, group ownership, delegates, and callbacks. Bridge termination will
call into carrier cleanup once native carriers are owned directly by the
bridge.
