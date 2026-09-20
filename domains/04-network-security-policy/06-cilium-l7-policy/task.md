# Scenario: L7 CiliumNetworkPolicy — Method and Path Restrictions

**Domain:** Network Security and Policy (25%)
**Competencies:** Securing Traffic with Network Policies

## Why this scenario exists

`domains/04-network-security-policy/01-network-policies` covers plain Kubernetes `NetworkPolicy`, which is strictly L3/L4 (IPs and ports) — it has no concept of HTTP methods or paths. Real-world beta feedback (`docs/exam-strategy.md`) explicitly calls out both L4 *and* L7 `CiliumNetworkPolicy` as exam-relevant, and this repo previously had no dedicated L7 exercise.

## Context

Namespace `l7-lab` has `frontend` and `api` Deployments, Cilium installed with L7 proxy support. `frontend` legitimately needs to read from `api`, but must never be able to write to it — only `api`'s own internal jobs should be able to modify data.

## Task

Write a `CiliumNetworkPolicy` so that, for traffic from `frontend` to `api` on port 8080:

1. `GET /api/*` is allowed.
2. `POST /api/*` and `DELETE /api/*` are rejected — not merely "not explicitly allowed," but rejected as an HTTP-level policy decision, distinct from a connection-level drop.
3. Traffic to any pod other than `api` from `frontend` is unaffected by this policy (don't accidentally restrict frontend's other traffic).

## Success criteria

- `curl -X GET http://api:8080/api/anything` from `frontend` succeeds.
- `curl -X POST http://api:8080/api/anything` from `frontend` is rejected at the HTTP layer (an explicit 403-style rejection from the Cilium L7 proxy, not a connection timeout).
- `hubble observe --verdict DROPPED -f` shows the rejected POST with method and path visible in the flow — proof this is genuinely L7-aware, not just a port-level block.

## Official documentation

- Cilium L7 policy (HTTP-aware rules) — https://docs.cilium.io/en/stable/security/policy/language/#layer-7-examples
- Cilium Network Policy overview — https://docs.cilium.io/en/stable/security/policy/
