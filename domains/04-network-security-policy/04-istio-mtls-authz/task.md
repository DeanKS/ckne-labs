# Scenario: Istio PeerAuthentication and AuthorizationPolicy

**Domain:** Network Security and Policy (25%)
**Competencies:** Implementing Pod-level Authentication and Authorization

## Context

Real-world CKNE feedback from beta sitters (see `docs/exam-strategy.md`) flags Istio's `PeerAuthentication` and `AuthorizationPolicy` as a meaningfully-weighted part of the exam - the underlying skill being tested is the distinction between **authentication** (proving identity, mTLS between workloads) and **authorization** (deciding what an already-authenticated identity is allowed to do). Namespace `mesh-lab` is part of an Istio mesh, sidecar-injected, with `frontend` and `payments` Deployments.

## Task

1. Require strict mTLS for every workload in `mesh-lab` - no plaintext traffic accepted, from inside or outside the mesh.
2. Even with mTLS enforced, `payments` must additionally reject any request that isn't from the `frontend` ServiceAccount specifically - being "in the mesh" and encrypted is not enough to be authorized.
3. Demonstrate the difference: a request from an unauthenticated (non-mesh) source should fail for a different reason than a request from a mesh workload that isn't `frontend`.

## Success criteria

- `istioctl authn tls-check` (or equivalent) shows STRICT mode for `mesh-lab`.
- A plaintext request into `payments` is rejected at the TLS/identity layer.
- An mTLS-authenticated request from a workload other than `frontend` is rejected at the authorization layer (a different failure mode/status than the plaintext case).
- A request from `frontend`'s ServiceAccount succeeds.

## Official documentation

- PeerAuthentication reference - https://istio.io/latest/docs/reference/config/security/peer_authentication/
- AuthorizationPolicy reference - https://istio.io/latest/docs/reference/config/security/authorization-policy/
