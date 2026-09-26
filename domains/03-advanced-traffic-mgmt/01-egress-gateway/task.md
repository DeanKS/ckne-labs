# Scenario: Cilium Egress Gateway for a Fixed Source IP

**Domain:** Advanced Traffic Management (20%)
**Competencies:** Configuring Egress Gateways for Cluster Exit Traffic

## Context

Pods in namespace `ai-workload` call an external API at `203.0.113.0/24` that allowlists a single source IP. Cluster nodes have dynamic/pooled egress IPs today, so the external vendor can't allowlist any one node.

## Task

Configure a `CiliumEgressGatewayPolicy` named `egress-external-api` so that all traffic from pods in `ai-workload` destined for `203.0.113.0/24` egresses through one designated gateway node, using a specific egress IP (`10.168.60.100`, already assigned as a secondary address on that node).

## Success criteria

- Traffic from `ai-workload` pods to `203.0.113.0/24` always shows source IP `10.168.60.100` at the destination.
- Traffic to any other destination from the same pods is unaffected (still uses normal node-based SNAT).
- If the gateway node goes down, `CiliumEgressGatewayPolicy` status reflects that egress for this policy is currently unavailable rather than silently failing over.

## Official documentation

- Cilium Egress Gateway - https://docs.cilium.io/en/latest/network/egress-gateway/
