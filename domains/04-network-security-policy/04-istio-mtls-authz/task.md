# Scenario: Istio Ambient PeerAuthentication and AuthorizationPolicy

**Domain:** Network Security and Policy (25%)  
**Competencies:** Implementing Pod-level Authentication and Authorization

## Context

This scenario uses **Istio Ambient mode**.

Unlike traditional Istio sidecar mode, Ambient mode does not inject an Envoy proxy into each application Pod. Instead:

- **ztunnel** provides the secure Layer 4 (L4) data plane.
- Workload-to-workload traffic in the ambient mesh uses **HBONE with mTLS**.
- L4 `AuthorizationPolicy` rules can be enforced directly by ztunnel.
- A **waypoint proxy** is required for L7 features such as HTTP method, path, and header-based authorization.

Istio Ambient mode is enabled for the `mesh-lab` namespace by the lab setup.

The namespace contains three workloads:

- `frontend`
- `payments`
- `other-svc`

Each workload uses its own Kubernetes ServiceAccount:

```text
frontend   → frontend-sa
payments   → payments-sa
other-svc  → other-svc-sa
```

The lab setup does **not** create a `PeerAuthentication` or `AuthorizationPolicy`. Those resources are intentionally left for you to implement.

Istio's Ambient documentation describes this layered model: ztunnel provides L4 security and authentication, while waypoints provide optional L7 processing.

---

## Task

Configure the `mesh-lab` namespace so that:

### 1. Require strict mTLS

Create a namespace-wide `PeerAuthentication` that requires:

```text
STRICT
```

mTLS for workloads in `mesh-lab`.

Traffic from workloads outside the Ambient mesh must not be able to bypass the mTLS requirement.

Do **not** use sidecar injection for this task.

---

### 2. Restrict access to `payments`

Create an `AuthorizationPolicy` for the `payments` workload.

Only the `frontend` ServiceAccount should be permitted to connect to `payments`.

The policy should use the workload's Istio identity/principal:

```text
cluster.local/ns/mesh-lab/sa/frontend-sa
```

Do not base the policy on:

- Pod name
- Deployment name
- Service name
- Pod IP

This is an **L4 identity-based authorization policy**.

A waypoint is **not required** for this task.

---

### 3. Demonstrate the difference between authentication and authorization

Demonstrate three cases:

#### Case A — non-mesh source

A workload outside the Ambient mesh attempts to connect to `payments`.

The request should fail because the destination requires mTLS and the source does not have an Istio Ambient identity.

#### Case B — authenticated but unauthorized workload

`other-svc` attempts to connect to `payments`.

`other-svc` is part of the Ambient mesh and therefore has an authenticated Istio workload identity, but its ServiceAccount is not permitted by the `AuthorizationPolicy`.

The request should therefore be rejected by the authorization layer.

#### Case C — authenticated and authorized workload

`frontend` attempts to connect to `payments`.

Its ServiceAccount is explicitly allowed by the `AuthorizationPolicy`, so the request should succeed.

---

## Constraints

This scenario is specifically testing **Istio Ambient mode**.

Do not:

- enable `istio-injection=enabled`
- inject an `istio-proxy` sidecar
- use `kubectl exec ... -c istio-proxy`
- create a waypoint
- use L7 HTTP authorization rules

The authorization policy should remain an **L4 principal-based policy**.

---

## Success criteria

### Ambient enrollment

`mesh-lab` is enrolled in Ambient mode:

```bash
kubectl get namespace mesh-lab --show-labels
```

The namespace should have:

```text
istio.io/dataplane-mode=ambient
```

and should not rely on:

```text
istio-injection=enabled
```

The workloads should not contain an injected `istio-proxy` sidecar.

---

### ztunnel sees the workloads

Verify the workloads are enrolled in the Ambient data plane:

```bash
istioctl ztunnel-config workloads -n istio-system | grep mesh-lab
```

The workloads should appear as Ambient/HBONE workloads.

---

### Strict mTLS

A `PeerAuthentication` exists in `mesh-lab` with:

```yaml
spec:
  mtls:
    mode: STRICT
```

Verify:

```bash
kubectl get peerauthentication -n mesh-lab
```

---

### Authorization policy

An `AuthorizationPolicy` exists that selects:

```text
app=payments
```

and permits only:

```text
cluster.local/ns/mesh-lab/sa/frontend-sa
```

Verify:

```bash
kubectl get authorizationpolicy -n mesh-lab
```

---

### Behaviour

The final behaviour should be:

| Source | Ambient identity | Authorised | Expected result |
|---|---|---|---|
| Non-mesh workload | No | No | Rejected by STRICT mTLS |
| `other-svc` | Yes | No | Rejected by L4 AuthorizationPolicy |
| `frontend` | Yes | Yes | Allowed |

The exact client-side error for the rejected cases may differ depending on where the connection is terminated. Do not rely solely on an HTTP `403`; the important distinction is **mTLS failure versus authenticated-but-unauthorised traffic**.

---

## Troubleshooting hints

If `PeerAuthentication` cannot be created and Kubernetes reports:

```text
no matches for kind "PeerAuthentication"
```

check that the Istio CRDs are installed:

```bash
kubectl get crd peerauthentications.security.istio.io
```

If the workload appears to have an `istio-proxy` container, check for an unwanted sidecar injection label:

```bash
kubectl get namespace mesh-lab --show-labels
```

If the namespace has:

```text
istio-injection=enabled
```

remove it:

```bash
kubectl label namespace mesh-lab istio-injection-
```

Then ensure Ambient mode is enabled:

```bash
kubectl label namespace mesh-lab \
  istio.io/dataplane-mode=ambient \
  --overwrite
```

If the `AuthorizationPolicy` does not behave as expected, inspect the workload identity and ServiceAccount:

```bash
kubectl -n mesh-lab get pods
kubectl -n mesh-lab get serviceaccounts
```

Remember that the policy uses the **Istio principal**, not the Pod or Deployment name.

---

## Key exam concept

Keep these two questions separate:

```text
PeerAuthentication
        ↓
"Is this connection using the required authentication/mTLS?"

AuthorizationPolicy
        ↓
"Is this authenticated identity allowed to communicate with this workload?"
```

In Ambient mode:

```text
mTLS / L4 authentication
        ↓
      ztunnel
        ↓
L4 identity authorization
        ↓
      ztunnel
        ↓
    application
```

For L7 authorization:

```text
client
  ↓
ztunnel
  ↓
waypoint
  ↓
application
```

A waypoint is only needed when the scenario requires L7 features such as HTTP methods, paths, headers, routing, or other application-layer processing.

## Official documentation

- [Istio Ambient: Add workloads to the mesh](https://istio.io/latest/docs/ambient/usage/add-workloads/?utm_source=chatgpt.com)
- [Istio PeerAuthentication reference](https://istio.io/latest/docs/reference/config/security/peer_authentication/?utm_source=chatgpt.com)
- [Istio Ambient L4 security policy](https://istio.io/latest/docs/ambient/usage/l4-policy/?utm_source=chatgpt.com)
- [Istio AuthorizationPolicy reference](https://istio.io/latest/docs/reference/config/security/authorization-policy/?utm_source=chatgpt.com)
- [Istio waypoint proxies](https://istio.io/latest/docs/ambient/usage/waypoint/?utm_source=chatgpt.com)