# Plugin Loading

`mob_wifi` exposes its plugin metadata in `priv/mob_plugin.exs`.

The manifest is intentionally data-only so Mob core can load it without
starting the OTP application or touching native code. It includes:

- plugin name and spec version
- compatible Mob version
- recognized carriers
- primary carrier
- platform-specific permission and framework metadata

## Activation Flow

1. Mob core discovers `priv/mob_plugin.exs`.
2. Mob validates the plugin spec version and compatible Mob version.
3. Host configuration is passed to `Mob.Wifi.validate_config/1`.
4. The selected bridge module comes from `Mob.Wifi.bridge_module/0`.
5. The bridge is started with an explicit `:event_target`.

## Forward Compatibility

Unknown config keys are tolerated by the package so future Mob core versions
can pass additional metadata without breaking older `mob_wifi` releases.
Carrier drift remains strict: unsupported carrier values raise
`Mob.Wifi.CarrierRejectedError`.
