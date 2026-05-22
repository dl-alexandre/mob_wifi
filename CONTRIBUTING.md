# Contributing

## Local Checks

Run these before opening a pull request:

```bash
mix format --check-formatted
mix test
```

## Scope

Keep native carrier work isolated behind `Mob.Wifi.Carrier`. Changes to bridge
events, carrier policy, or config validation should include tests and docs.

## Native Work

Do not mark a carrier production-ready until the hardware validation matrix is
complete and documented in `docs/CARRIER_DECISION.md`.
