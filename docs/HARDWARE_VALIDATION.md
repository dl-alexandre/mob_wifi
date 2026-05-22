# Hardware Validation

Hardware validation is opt-in and separate from normal CI. Public GitHub
runners do not have attached Android or iOS devices, so the default test suite
excludes hardware tests.

## Current Readiness Command

```bash
mix mob_wifi.hardware.check
```

Use strict mode when a lab machine is expected to have every validation lane
available:

```bash
mix mob_wifi.hardware.check --strict
```

## Environment Variables

These variables identify the intended device pairings for future hardware
tests:

```bash
export MOB_WIFI_ANDROID_A=5200f354f4fb277f
export MOB_WIFI_ANDROID_B=R52W90AW7EN
export MOB_WIFI_IOS_A=00008030-000209510ED0C02E
export MOB_WIFI_IOS_B=2aa4be71ef18d7cb65191287cbc729b91e3f0635
```

## ExUnit Tags

Hardware tests must be tagged and remain excluded by default:

```elixir
@tag :hardware
@tag carrier: :wifi_direct
@tag platform: :android
test "discovers Android WiFi Direct peers" do
  ...
end
```

Run them explicitly:

```bash
mix test --include hardware
```

## Validation Lanes

| Lane | Requirement | Purpose |
| --- | --- | --- |
| `:android_wifi_direct` | two Android devices with `android.hardware.wifi.direct` | Android-to-Android WiFi Direct validation |
| `:android_wifi_aware` | two Android devices with `android.hardware.wifi.aware` | Future Android WiFi Aware validation |
| `:ios_multipeer` | two online iOS devices | iOS-to-iOS Multipeer validation |
| `:bonjour_tcp_cross_platform` | at least one Android and one iOS device | Android/iOS Bonjour/TCP validation |

## Self-Hosted CI

Hardware CI should use a controlled self-hosted macOS runner:

```yaml
runs-on: [self-hosted, macOS, mob-wifi-hardware]
```

Do not add hardware jobs to public hosted runners.
