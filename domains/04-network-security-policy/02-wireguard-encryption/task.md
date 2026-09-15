# Scenario: Node-to-Node Encryption with WireGuard

**Domain:** Network Security and Policy (25%)
**Competencies:** Implementing Node and Pod Level Encryption

## Task

Enable transparent node-to-node encryption for all pod traffic crossing node boundaries, using Cilium's WireGuard datapath — without requiring any application-level TLS changes.

## Success criteria

- `cilium-dbg status` reports encryption as WireGuard and Enabled on every node.
- Cross-node pod-to-pod traffic is encrypted in transit (verifiable by packet capture showing WireGuard UDP traffic between node IPs rather than cleartext pod traffic).
- Same-node pod-to-pod traffic is unaffected (WireGuard only protects traffic that actually crosses the node boundary).

## Official documentation

- Cilium WireGuard node-to-node encryption — https://docs.cilium.io/en/stable/security/network/encryption-wireguard/
