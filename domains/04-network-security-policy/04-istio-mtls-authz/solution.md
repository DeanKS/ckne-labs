# Solution: Istio Strict mTLS + Authorization

## The concept the exam is actually testing

`PeerAuthentication` answers "who is this, cryptographically" - it's the mTLS layer, workload identity via SPIFFE certificates issued automatically by Istio's control plane. `AuthorizationPolicy` answers "given that I know who you are, are you allowed to do this" - it's evaluated **after** peer authentication succeeds. A request can pass PeerAuthentication (valid mTLS, real workload identity) and still be denied by AuthorizationPolicy. A request can also never reach AuthorizationPolicy at all because it failed PeerAuthentication first. Being able to say which layer rejected a given request - not just "it failed" - is the actual skill.

## Step 1: Strict mTLS for the namespace

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

Naming it `default` and putting it at the namespace level (no `selector`) makes it the namespace-wide policy - Istio falls back to the mesh-wide default only if no namespace-level `PeerAuthentication` named `default` exists, so this one setting governs every workload in `mesh-lab` unless a workload-specific `PeerAuthentication` overrides it.

## Step 2: Restrict `payments` to only accept `frontend`

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
        principals: ["cluster.local/ns/mesh-lab/sa/frontend-sa"]
```

Once any `AuthorizationPolicy` with `action: ALLOW` selects a workload, that workload moves to default-deny for everything not explicitly matched - there's no need for a separate explicit deny rule for `other-svc`; the absence of a matching `ALLOW` rule is itself the denial.

## Verify the two distinct failure modes

```bash
# 1. Plaintext from outside the mesh -> fails at the TLS/identity layer (connection reset,
#    not an HTTP-level 403) because STRICT mode refuses unencrypted connections outright
kubectl -n mesh-lab run plaintext-test --image=curlimages/curl --rm -it --restart=Never -- \
  curl -v http://payments.mesh-lab.svc.cluster.local

# 2. mTLS-authenticated request from other-svc -> connects fine at the TLS layer, but gets
#    an explicit HTTP 403 from the Envoy sidecar because AuthorizationPolicy denies it
kubectl -n mesh-lab exec deploy/other-svc -c istio-proxy -- \
  curl -s -o /dev/null -w "%{http_code}" http://payments.mesh-lab.svc.cluster.local

# 3. frontend -> succeeds
kubectl -n mesh-lab exec deploy/frontend -c istio-proxy -- \
  curl -s -o /dev/null -w "%{http_code}" http://payments.mesh-lab.svc.cluster.local
```

Case 1 fails at the connection level (no valid mTLS handshake possible from a non-mesh source). Case 2 gets a clean HTTP 403 - proof it authenticated successfully and was still denied. Distinguishing these two in a live cluster, under time pressure, is exactly the skill this competency is checking for.

## Common failure modes

- Writing the `AuthorizationPolicy` with `principals` referencing the wrong SPIFFE format - it's always `cluster.local/ns/<namespace>/sa/<service-account-name>`, not the pod name or Deployment name.
- Forgetting `action: ALLOW` shifts the selected workload to default-deny - people sometimes add an explicit `DENY` policy for every other workload instead, which is redundant and, if written even slightly wrong, can accidentally allow something the single `ALLOW` policy would have blocked.
- Testing mTLS enforcement with `kubectl exec` into the app container instead of the `istio-proxy` sidecar container - traffic initiated from inside the app container still gets intercepted and wrapped by the sidecar's iptables rules in most setups, but if you're troubleshooting and get confused about what's actually encrypted, running the test `curl` from the sidecar explicitly removes that ambiguity.
