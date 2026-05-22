# Carrier Decision

## Current Decision

`mob_wifi` recognizes three carriers:

- `:wifi_direct` for Android-to-Android transport.
- `:multipeer` for iOS-to-iOS transport.
- `:bonjour_tcp` for Android/iOS interop where both devices can share an IP
  topology.

The initial bridge only implements the `:wifi_direct` startup path. The other
carriers are manifest-level commitments and documentation targets until native
code and hardware evidence are available.

## Decision Matrix

| Carrier | Range | Power | Discovery Time | Reliability | Platform Limits |
| --- | --- | --- | --- | --- | --- |
| Android WiFi Direct | Medium | Medium during discovery, better for large transfers | Medium | Good after group formation | Android-only and permission-sensitive |
| iOS Multipeer | Short to medium | OS-managed | Usually fast | Good for iOS peers | Apple ecosystem only |
| Bonjour/TCP | Network-dependent | Good after association | Depends on topology | Good with TCP, custom work for UDP | Requires shared IP topology |
| WiFi Aware | Short to medium | Designed for discovery efficiency | Fast when supported | Android feature-gated, deferred |

## Platform Notes

Android exposes WiFi Direct through `WifiP2pManager`. That is the right first
Android carrier because it supports peer discovery, connection setup, and socket
traffic without relying on infrastructure WiFi.

Android WiFi Aware remains a later candidate. It needs runtime feature checks
and a separate validation pass before it should be part of the default carrier
policy.

iOS does not expose a general-purpose WiFi Direct API for third-party apps.
Multipeer Connectivity is the first iOS-to-iOS carrier because it is the Apple
framework designed for nearby peer discovery and communication.

Android-to-iOS should not be described as Multipeer Connectivity. The practical
cross-platform path is Bonjour/mDNS discovery plus TCP/UDP once both devices
share a usable IP topology.

## Required Evidence

- Android-to-Android WiFi Direct discovery, reconnect, and frame transfer.
- iOS-to-iOS Multipeer discovery, reconnect, and frame transfer.
- Android-to-iOS Bonjour/TCP discovery and transport over the intended topology.
- Battery impact under idle discovery and active transfer.
- Background behavior on locked devices and app lifecycle transitions.
- Maximum frame size, fragmentation requirements, and retry behavior.

## Rejected Initial Claims

- `:wifi_aware` is not a supported config carrier yet. It is promising but must
  be validated separately.
- iOS true WiFi Direct is not assumed available.
- Multipeer Connectivity is not treated as an Android interop layer.
