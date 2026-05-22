# Security Model

`mob_wifi` does not treat WiFi association as peer authentication.

## Threat Model

The transport must assume nearby devices can observe discovery metadata and
that local networks may be hostile. Carrier discovery is only a way to find a
candidate endpoint; application identity and message confidentiality must be
provided above the raw WiFi carrier.

## Planned Controls

- Authenticate peers with the Mob identity layer.
- Encrypt frames before they enter the carrier using the shared Mob security
  envelope, such as Noise or app-level AEAD.
- Bind sessions to peer identity, not to IP address, MAC address, or Multipeer
  display name.
- Avoid logging frame bodies or high-cardinality secrets.

## Delivery Semantics

The bridge currently exposes best-effort frame send semantics. Reliable
delivery, sequencing, acknowledgements, and retransmission belong in a later
transport reliability layer once the carrier topology is validated.
