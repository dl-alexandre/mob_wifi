# Performance Tuning

`mob_wifi` starts with conservative defaults because carrier behavior varies
heavily by platform, chipset, OS version, and app lifecycle state.

## Frame Size

`max_frame_bytes` defaults to `262_144`. This is a bridge guardrail, not a
promise that every carrier can deliver one frame without fragmentation.

Native carriers should report their tested frame budget and reject oversized
frames before allocating large intermediate buffers.

## Discovery

Discovery is usually the expensive phase. Carrier adapters should avoid
unbounded scanning and expose refresh intervals that can be tuned by mode:

- `:production` should prefer conservative discovery windows.
- `:test` may increase logging and shorten retry intervals.
- `:simulation` should avoid native discovery entirely.

## Reliability

The current bridge exposes best-effort delivery. TCP carriers can provide
ordered byte streams underneath the frame API. UDP carriers must add sequencing,
ACKs, duplicate suppression, and retransmission before being marked production
ready.

## Telemetry

Use the built-in telemetry events to measure frame sizes, error rates, peer
flap rates, and startup frequency before changing carrier defaults.
