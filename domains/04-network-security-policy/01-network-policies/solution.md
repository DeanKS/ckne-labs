# Solution: Default-Deny with Explicit Allows

## Order of operations matters

Apply default-deny *and* the explicit allows in the same batch, not default-deny first and allows "later" — between those two steps, DNS breaks for every pod in the namespace and anything mid-flight can look like a false failure during testing.

## Manifests

```yaml
# 1. Default deny all ingress+egress in the namespace
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: secure-app
spec:
  podSelector: {}
  policyTypes: ["Ingress", "Egress"]
---
# 2. frontend -> backend on 8080
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: secure-app
spec:
  podSelector:
    matchLabels: {app: backend}
  policyTypes: ["Ingress"]
  ingress:
  - from:
    - podSelector: {matchLabels: {app: frontend}}
    ports:
    - protocol: TCP
      port: 8080
---
# 3. backend -> db on 5432
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-backend-to-db
  namespace: secure-app
spec:
  podSelector:
    matchLabels: {app: db}
  policyTypes: ["Ingress"]
  ingress:
  - from:
    - podSelector: {matchLabels: {app: backend}}
    ports:
    - protocol: TCP
      port: 5432
---
# 4. Egress allowed FROM frontend and backend TO db/backend respectively — the mirror side
#    of policies 2/3, since NetworkPolicy ingress rules don't imply the source's egress is open
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-app-egress
  namespace: secure-app
spec:
  podSelector: {}
  policyTypes: ["Egress"]
  egress:
  - to:
    - podSelector: {matchLabels: {app: backend}}
    ports: [{protocol: TCP, port: 8080}]
  - to:
    - podSelector: {matchLabels: {app: db}}
    ports: [{protocol: TCP, port: 5432}]
---
# 5. DNS egress to kube-system for every pod in the namespace
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns-egress
  namespace: secure-app
spec:
  podSelector: {}
  policyTypes: ["Egress"]
  egress:
  - to:
    - namespaceSelector:
        matchLabels: {kubernetes.io/metadata.name: kube-system}
    ports:
    - {protocol: UDP, port: 53}
    - {protocol: TCP, port: 53}
---
# 6. Ingress to frontend from anywhere on port 80
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-external-to-frontend
  namespace: secure-app
spec:
  podSelector: {matchLabels: {app: frontend}}
  policyTypes: ["Ingress"]
  ingress:
  - ports: [{protocol: TCP, port: 80}]
```

## The mistake almost everyone makes here

`NetworkPolicy` ingress and egress rules are evaluated independently per pod — allowing ingress *to* `backend` from `frontend` does **not** automatically allow egress *from* `frontend`. Both sides of the connection need a matching rule once default-deny egress is in effect on the source pod. That's why policy #4 exists separately from #2/#3 — a common exam trap is writing only the ingress-side allow and being confused why traffic still doesn't flow.

## Common failure modes

- Forgetting DNS egress entirely — once default-deny-egress is applied, every pod loses the ability to resolve `backend.secure-app.svc.cluster.local` or any external name, even though the actual data-plane rule you wrote is otherwise correct.
- Using `kubernetes.io/metadata.name` for the `kube-system` namespaceSelector — this label is automatically applied by Kubernetes since 1.21+, but if you're on an old test cluster it might not exist; verify with `kubectl get ns kube-system --show-labels` before relying on it.
- Not restricting `allow-external-to-frontend`'s `from` — leaving it unrestricted (as required here) is correct for "reachable from outside the cluster," but double check that's actually the requirement before doing it in a real environment.
