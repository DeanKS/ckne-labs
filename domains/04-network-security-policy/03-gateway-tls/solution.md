# Solution: Gateway TLS Termination + BackendTLSPolicy + Least-Privilege RBAC

## 1. HTTPS listener with TLS termination

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: public-gw
  namespace: gw-lab
spec:
  gatewayClassName: <your-installed-class>
  listeners:
  - name: http
    protocol: HTTP
    port: 80
  - name: https
    protocol: HTTPS
    port: 443
    tls:
      mode: Terminate
      certificateRefs:
      - name: orders-tls
```

Design choice: keep the `http` listener but decide explicitly. For this scenario, redirect rather than disable — disabling breaks any client that hasn't updated its URLs yet, and a redirect is the more common real-world answer to "must support HTTPS" without breaking things:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: http-to-https-redirect
  namespace: gw-lab
spec:
  parentRefs:
  - name: public-gw
    sectionName: http
  rules:
  - filters:
    - type: RequestRedirect
      requestRedirect:
        scheme: https
        statusCode: 301
```

## 2. BackendTLSPolicy for the Gateway-to-backend hop

`BackendTLSPolicy` attaches to the **Service**, not the Gateway or the Route — it's how you tell any Gateway API implementation "when you forward to this backend, validate its cert against this CA and this expected hostname":

```yaml
apiVersion: gateway.networking.k8s.io/v1alpha3
kind: BackendTLSPolicy
metadata:
  name: orders-v2-backend-tls
  namespace: gw-lab
spec:
  targetRefs:
  - group: ""
    kind: Service
    name: orders-v2
  validation:
    caCertificateRefs:
    - name: orders-ca
      group: ""
      kind: ConfigMap
    hostname: orders-v2.gw-lab.svc.cluster.local
```

This only works if `orders-v2`'s Service port is annotated/configured as an HTTPS backend (implementation-specific — check your GatewayClass's docs) so the Gateway knows to speak TLS rather than plaintext HTTP on that hop.

## 3. Least-privilege RBAC for orders-v2

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: orders-v2-sa
  namespace: gw-lab
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: orders-v2-configmap-reader
  namespace: gw-lab
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list", "watch"]
  resourceNames: []   # scope further to named ConfigMaps if you know them in advance
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: orders-v2-configmap-reader-binding
  namespace: gw-lab
subjects:
- kind: ServiceAccount
  name: orders-v2-sa
  namespace: gw-lab
roleRef:
  kind: Role
  name: orders-v2-configmap-reader
  apiGroup: rbac.authorization.k8s.io
```

Deliberately a `Role`, not `ClusterRole` — a `ClusterRole`+`ClusterRoleBinding` would grant the permission cluster-wide across every namespace, which fails the "nothing cluster-wide" requirement even if the verbs themselves look identical.

Then set `spec.template.spec.serviceAccountName: orders-v2-sa` on the `orders-v2` Deployment and confirm the default token auto-mount isn't giving it anything extra — `automountServiceAccountToken: true` is the default and fine here since the RBAC itself is what's scoped, not the token's existence.

## Verify least privilege

```bash
kubectl auth can-i list secrets --as=system:serviceaccount:gw-lab:orders-v2-sa -A       # should be "no"
kubectl auth can-i list pods --as=system:serviceaccount:gw-lab:orders-v2-sa --all-namespaces  # should be "no"
kubectl auth can-i get configmaps --as=system:serviceaccount:gw-lab:orders-v2-sa -n gw-lab    # should be "yes"
```

## Common failure modes

- Using a `ClusterRole`/`ClusterRoleBinding` "because it's easier" — grants far more than required and directly fails a least-privilege requirement even if functionally it also "works."
- Forgetting `BackendTLSPolicy` is namespaced to `targetRefs` on a **Service**, and trying to attach it to the `Gateway` or `HTTPRoute` instead — it will simply not apply.
- Skipping the redirect route and just leaving HTTP up unchanged — the requirement said clients "must connect over HTTPS," which the plain existence of an HTTPS listener doesn't guarantee if HTTP still serves the same content unredirected.
