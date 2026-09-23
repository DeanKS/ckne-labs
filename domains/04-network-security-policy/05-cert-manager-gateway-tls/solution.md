# Solution: cert-manager + Gateway API

## Why a real setup needs an Issuer, not just a Certificate

cert-manager's `Certificate` object is a *request*, not a source of truth on its own - it always needs a paired `ClusterIssuer` (or namespaced `Issuer`) that says how to actually get a cert signed. In production that's usually Let's Encrypt via `ACME` with an HTTP-01 or DNS-01 solver; for a local, offline lab, `SelfSigned` is the closest stand-in that still exercises the same reconciliation loop.

## Issuer + Certificate

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-issuer
spec:
  selfSigned: {}
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: orders-tls-managed
  namespace: gw-lab
spec:
  secretName: orders-tls-managed
  dnsNames:
    - orders.example.com
  issuerRef:
    name: selfsigned-issuer
    kind: ClusterIssuer
  duration: 2160h      # 90 days
  renewBefore: 360h    # renew 15 days before expiry
```

`secretName` is the Secret cert-manager will create and keep in sync - that's the name you point the Gateway at, not the Certificate object's own name (they happen to match here for clarity, but Kubernetes doesn't require it).

## Point the Gateway at it

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: public-gw
  namespace: gw-lab
spec:
  listeners:
  - name: https
    protocol: HTTPS
    port: 443
    tls:
      mode: Terminate
      certificateRefs:
      - name: orders-tls-managed   # now cert-manager-owned, not scenario 03's manual Secret
```

## What happens on deletion or renewal failure

Deleting the `Certificate` object does **not** immediately delete the Secret by default - cert-manager leaves the last-known-good Secret in place unless you've explicitly configured `Certificate` deletion to cascade (it doesn't by default), which means the Gateway keeps serving the last issued cert until it actually expires. A **failed renewal**, by contrast, is silent to the Gateway entirely: the Gateway has no idea cert-manager is unhappy, it just keeps using whatever's currently in the Secret - this is why `kubectl describe certificate` (checking the `Ready` condition and any `Issuing`/error events) is the thing to actually monitor, not the Gateway's own status, which will look perfectly healthy right up until the old cert expires and clients start failing TLS validation.

```bash
kubectl -n gw-lab describe certificate orders-tls-managed | grep -A5 "Status:"
kubectl -n gw-lab get certificate orders-tls-managed -o jsonpath='{.status.renewalTime}'
```

## Common failure modes

- Pointing the Gateway at the `Certificate` object's name instead of its `secretName` - they can differ, and the Gateway only ever reads Secrets, never Certificate objects directly.
- Assuming a `Ready: True` Certificate means the Gateway is definitely using it - if the Gateway's `certificateRefs` still points at the old scenario-03 Secret name, everything looks healthy independently and the mismatch is easy to miss without explicitly diffing the two names.
- Not setting `renewBefore` and assuming cert-manager renews "in time" by some universal default - the default renewal window is relative to the certificate's total duration, so for a very long-duration cert the absolute time to renewal can be longer than expected.
