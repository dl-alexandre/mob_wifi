# Testing Strategy

## Elixir Layer

The current test suite validates the Mob-facing surface without requiring
Android or iOS hardware:

- public API and carrier policy
- config validation and carrier rejection
- bridge start errors
- frame delivery through an injected native client
- frame-size guardrails
- canonical event delivery to `event_target`
- telemetry events for bridge start, send, receive, and error paths

## Native Layer

Native work should add hardware-backed tests for:

- Android-to-Android WiFi Direct discovery and reconnect
- iOS-to-iOS Multipeer discovery and reconnect
- Android-to-iOS Bonjour/TCP discovery over the intended topology
- locked-device and background lifecycle behavior
- battery draw during idle discovery and active transfer

## CI

CI runs formatting and tests for the Elixir layer. Native hardware validation
should run separately because it requires controlled devices and network
conditions.
