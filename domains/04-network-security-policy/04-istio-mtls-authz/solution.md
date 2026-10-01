# Solution: Istio Ambient Strict mTLS + Authorization

## The concept the exam is actually testing

This lab uses **Istio Ambient mode**, so the security model is different from traditional sidecar-based Istio.

In Ambient mode:

- **ztunnel** provides the secure L4 overlay between workloads.
- Traffic between ambient workloads uses **HBONE**, which provides mTLS encryption and workload identity.
- `PeerAuthentication` controls the mTLS requirements for incoming traffic.
- L4 `AuthorizationPolicy` is enforced by the destination workload's **ztunnel**.
- L7 authorization based on HTTP methods, paths, headers, etc. requires an **Istio waypoint**.

For this lab, the important distinction is:

> **PeerAuthentication answers "can this connection establish an authenticated, encrypted connection?"**

> **AuthorizationPolicy answers "given the authenticated workload identity, is this workload allowed to connect?"**

A request can therefore have valid mTLS and still be rejected by `AuthorizationPolicy`.

Conversely, traffic that cannot establish the required mTLS connection can be rejected before an identity-based authorization policy can allow it.

The ability to identify **which security layer rejected a request** is more important than simply knowing that the request failed.

---

## Step 1: Enrol the namespace in Ambient mode

The `setup.sh` script configures `mesh-lab` for Istio Ambient mode:

```bash
kubectl label namespace mesh-lab \
  istio.io/dataplane-mode=ambient \
  --overwrite
```

Verify:

```bash
kubectl get namespace mesh-lab --show-labels
```

You should see:

```text
istio.io/dataplane-mode=ambient
```

There should **not** be an `istio-injection=enabled` label. That label belongs to the traditional sidecar model and is not used by this lab.

Verify that the workloads are running without injected sidecars:

```bash
kubectl -n mesh-lab get pods
```

The application Pods should contain their normal application containers; there should not be an `istio-proxy` sidecar container.

Ambient traffic is handled by the node-local `ztunnel` rather than an Envoy sidecar injected into each application Pod.

---

## Step 2: Configure strict mTLS

Create a namespace-wide `PeerAuthentication`:

```yaml
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: default
  namespace: mesh-lab
spec:
  mtls:
    mode: STRICT
```

Apply it:

```bash
kubectl apply -f 04-04-pa.yaml
```

Verify:

```bash
kubectl get peerauthentication -n mesh-lab
```

The `default` policy applies to workloads in the `mesh-lab` namespace because it has no workload selector.

In Ambient mode, `STRICT` means that workloads will only accept traffic using the Istio mTLS-secured path. Traffic arriving without a valid mTLS identity is rejected.

The important difference from sidecar mode is **where this enforcement happens**:

```text
Sidecar mode:
client → Envoy sidecar → network → Envoy sidecar → application

Ambient mode:
client → ztunnel → HBONE/mTLS → ztunnel → application
```

There is no `istio-proxy` sidecar involved in this lab.

---

## Step 3: Restrict `payments` to `frontend`

Create an L4 `AuthorizationPolicy`:

```yaml
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: payments-allow-frontend-only
  namespace: mesh-lab
spec:
  selector:
    matchLabels:
      app: payments
  action: ALLOW
  rules:
  - from:
    - source:
        principals:
        - "cluster.local/ns/mesh-lab/sa/frontend-sa"
```

Apply it:

```bash
kubectl apply -f 04-04-authz.yaml
```

Verify:

```bash
kubectl get authorizationpolicy -n mesh-lab
```

The important part is the workload identity:

```text
cluster.local/ns/mesh-lab/sa/frontend-sa
```

This is the SPIFFE-style identity issued to the `frontend` workload.

It is based on:

```text
cluster.local
└── ns/mesh-lab
    └── sa/frontend-sa
```

It is **not** based on:

- Pod name
- Deployment name
- Service name
- Pod IP

Because the policy only checks the source principal, this is an **L4 authorization policy** and can be enforced directly by ztunnel. A waypoint is not required.

---

## Why `action: ALLOW` creates default-deny behaviour

Once an `ALLOW` policy selects a workload, traffic that doesn't match one of its `ALLOW` rules is denied.

Therefore:

```text
frontend → payments
        ↓
principal matches
        ↓
ALLOW
```

while:

```text
other-svc → payments
          ↓
principal does not match
          ↓
DENY
```

There is no need to create a separate `DENY` policy for `other-svc`.

---

# Verify the two security layers

The useful troubleshooting model is:

```text
                    ┌─────────────────────┐
                    │   Incoming traffic  │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │ ztunnel / mTLS      │
                    │ PeerAuthentication   │
                    └──────────┬──────────┘
                               │
                         authenticated
                               │
                               ▼
                    ┌─────────────────────┐
                    │ ztunnel / L4 AuthZ  │
                    │ AuthorizationPolicy │
                    └──────────┬──────────┘
                               │
                              ALLOW
                               │
                               ▼
                         payments Pod
```

This distinction is particularly important in an exam troubleshooting scenario.

---

## 1. Test an in-mesh workload that is not authorised

Run a request from `other-svc`:

```bash
kubectl -n mesh-lab exec deploy/other-svc -- \
  curl -s -o /dev/null -w "%{http_code}\n" \
  http://payments.mesh-lab.svc.cluster.local
```

The request should be rejected by the L4 `AuthorizationPolicy`.

Depending on exactly where the connection is terminated and the Istio version, the client may report an RBAC/connection failure rather than necessarily producing the same HTTP-level response you would expect from a sidecar-based L7 policy.

The important point is that:

```text
other-svc
    │
    │ valid ambient identity
    ▼
ztunnel
    │
    │ AuthorizationPolicy rejects identity
    ▼
DENIED
```

The request has an Istio workload identity, but that identity is not permitted by the policy.

---

## 2. Test the authorised workload

Run the same request from `frontend`:

```bash
kubectl -n mesh-lab exec deploy/frontend -- \
  curl -s -o /dev/null -w "%{http_code}\n" \
  http://payments.mesh-lab.svc.cluster.local
```

This should return:

```text
200
```

because:

```text
frontend
    │
    │ principal:
    │ cluster.local/ns/mesh-lab/sa/frontend-sa
    ▼
ztunnel
    │
    │ AuthorizationPolicy matches
    ▼
payments
```

---

## 3. Test traffic from outside the Ambient mesh

A workload outside `mesh-lab` should not automatically receive an Ambient identity.

For example, create a separate namespace that is **not** labelled for Ambient mode:

```bash
kubectl create namespace outside-mesh
```

Run a test workload:

```bash
kubectl -n outside-mesh run plaintext-test \
  --image=curlimages/curl \
  --restart=Never \
  --command -- \
  sleep 3600
```

Then attempt to reach `payments`:

```bash
kubectl -n outside-mesh exec plaintext-test -- \
  curl -v http://payments.mesh-lab.svc.cluster.local
```

With `PeerAuthentication` set to `STRICT`, the destination requires mTLS. A plaintext connection from outside the mesh therefore cannot satisfy the mTLS requirement.

This is different from an authenticated but unauthorized Ambient workload:

```text
Outside mesh
     │
     │ plaintext / no Istio identity
     ▼
payments ztunnel
     │
     │ STRICT mTLS
     ▼
   REJECT


other-svc
     │
     │ valid Istio identity
     ▼
payments ztunnel
     │
     │ identity not allowed
     ▼
   REJECT


frontend
     │
     │ valid Istio identity
     ▼
payments ztunnel
     │
     │ identity allowed
     ▼
   ALLOW
```

---

# Important Ambient-mode distinction: L4 vs L7

This lab's `AuthorizationPolicy` only uses:

```yaml
source:
  principals:
```

That makes it an **L4 identity-based policy**, which ztunnel can enforce directly.

If the policy instead contained conditions such as:

```yaml
to:
- operation:
    methods: ["GET"]
    paths: ["/payments"]
```

that would introduce **L7 policy enforcement**.

ztunnel cannot enforce L7 attributes.

For L7 authorization in Ambient mode, traffic must be processed by an **Istio waypoint**, and the policy is normally attached to the waypoint using `targetRefs`.

This gives a useful exam rule:

| Requirement | Ambient enforcement |
|---|---|
| mTLS | ztunnel |
| Source principal | ztunnel |
| Source namespace | ztunnel |
| Source IP/port | ztunnel |
| HTTP method | Waypoint |
| HTTP path | Waypoint |
| HTTP headers | Waypoint |
| HTTP routing | Waypoint |

---

# Common failure modes

### `no matches for kind "PeerAuthentication"`

Check that the Istio CRDs are installed:

```bash
kubectl get crd peerauthentications.security.istio.io
```

If the CRD is missing, the Istio installation is incomplete.

---

### Namespace has `istio-injection=enabled`

That is the **sidecar injection** mechanism.

This lab uses Ambient mode, so the namespace should instead have:

```bash
kubectl label namespace mesh-lab \
  istio.io/dataplane-mode=ambient \
  --overwrite
```

Remove the old sidecar label if present:

```bash
kubectl label namespace mesh-lab istio-injection-
```

Then restart workloads if necessary.

---

### Looking for an `istio-proxy` container

Don't.

Ambient workloads do not require an Envoy sidecar:

```bash
kubectl -n mesh-lab get pods
```

The data plane is provided by the node-local `ztunnel`.

Check it with:

```bash
kubectl -n istio-system get pods -l app=ztunnel
```

---

### Assuming `AuthorizationPolicy` always means Envoy

In Ambient mode, an L4 `AuthorizationPolicy` can be enforced by **ztunnel**.

Only L7 authorization requires a waypoint/Envoy proxy.

---

### Using `-c istio-proxy`

This is a sidecar-mode command:

```bash
kubectl exec deploy/frontend -c istio-proxy -- ...
```

Do not use it in this lab.

Run the test from the application container instead:

```bash
kubectl -n mesh-lab exec deploy/frontend -- \
  curl ...
```

Traffic is still intercepted by the Ambient data plane because the workload is enrolled in the Ambient mesh.

---

### Confusing authentication with authorization

Remember:

```text
PeerAuthentication
        ↓
"Is this connection using the required mTLS/security mode?"

AuthorizationPolicy
        ↓
"Is this authenticated workload allowed to connect?"
```

A workload can therefore be:

```text
Authenticated + Authorized     → ALLOW
Authenticated + Unauthorized   → DENY
Unauthenticated + STRICT       → DENY
```

That distinction is the core concept this lab is designed to test.
