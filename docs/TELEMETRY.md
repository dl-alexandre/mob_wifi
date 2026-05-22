# Telemetry

`mob_wifi` emits low-cardinality telemetry events for bridge lifecycle, frame
traffic, peer state, and error paths.

## Events

| Event | Measurements | Metadata |
| --- | --- | --- |
| `[:mob_wifi, :bridge, :start]` | `%{system_time: integer()}` | `%{carrier: atom(), max_frame_bytes: pos_integer()}` |
| `[:mob_wifi, :bridge, :started]` | same as `:start` | same as `:start`; compatibility alias |
| `[:mob_wifi, :bridge, :stop]` | `%{system_time: integer()}` | `%{carrier: atom(), reason: term()}` |
| `[:mob_wifi, :bridge, :stopped]` | same as `:stop` | same as `:stop`; compatibility alias |
| `[:mob_wifi, :frame, :sent]` | `%{bytes: non_neg_integer()}` | `%{carrier: atom(), peer_id: String.t()}` |
| `[:mob_wifi, :frame, :send_error]` | `%{bytes: non_neg_integer()}` | `%{carrier: atom(), peer_id: String.t(), reason: term(), error: Mob.Wifi.Error.t()}` |
| `[:mob_wifi, :frame, :received]` | `%{bytes: non_neg_integer()}` | `%{peer_id: String.t()}` |
| `[:mob_wifi, :peer, :up]` | `%{count: 1}` | `%{peer_id: String.t()}` |
| `[:mob_wifi, :peer, :down]` | `%{count: 1}` | `%{peer_id: String.t()}` |
| `[:mob_wifi, :peer, :discovered]` | `%{count: 1}` | `%{peer_id: String.t(), carrier: atom() \| nil}` |
| `[:mob_wifi, :bridge, :error]` | `%{count: 1}` | `%{reason: term(), error: Mob.Wifi.Error.t()}` |

## Example Handler

```elixir
:telemetry.attach_many(
  "mob-wifi-logger",
  [
    [:mob_wifi, :bridge, :start],
    [:mob_wifi, :frame, :sent],
    [:mob_wifi, :frame, :send_error],
    [:mob_wifi, :bridge, :error]
  ],
  fn event, measurements, metadata, _config ->
    Logger.info("mob_wifi event=#{inspect(event)} measurements=#{inspect(measurements)} metadata=#{inspect(metadata)}")
  end,
  nil
)
```

Avoid logging frame bodies, credentials, session keys, or high-cardinality
native diagnostics from telemetry handlers.
