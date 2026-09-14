# Solution: Gateway API Header + Path Routing

## Why order matters in HTTPRoute rules

Gateway API evaluates `HTTPRoute` rules in the order they're written, first match wins — there's no automatic "most specific match" resolution the way some Ingress controllers do it by path length. So the canary (header-matched) rule has to come **before** the catch-all path rule, or the catch-all would swallow everything first.

## Manifests

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: public-gw
  namespace: gw-lab
spec:
  gatewayClassName: <your-installed-class>   # e.g. cilium
  listeners:
  - name: http
    protocol: HTTP
    port: 80
    allowedRoutes:
      namespaces:
        from: Same
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: orders-route
  namespace: gw-lab
spec:
  parentRefs:
  - name: public-gw
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /orders
      headers:
      - name: x-canary
        value: "true"
    backendRefs:
    - name: orders-v2
      port: 80
  - matches:
    - path:
        type: PathPrefix
        value: /orders
    backendRefs:
    - name: orders-v1
      port: 80
```

## Verify

```bash
GW_IP=$(kubectl -n gw-lab get gateway public-gw -o jsonpath='{.status.addresses[0].value}')
curl -s "http://${GW_IP}/orders"                        # -> v1
curl -s -H "x-canary: true" "http://${GW_IP}/orders"    # -> v2
kubectl -n gw-lab get httproute orders-route -o yaml | grep -A2 "type: Accepted"
kubectl -n gw-lab get httproute orders-route -o yaml | grep -A2 "type: ResolvedRefs"
```

## Common failure modes

- Putting the catch-all rule first: it matches `/orders` regardless of headers, so the canary rule never fires.
- Forgetting `allowedRoutes.namespaces.from` on the `Gateway` listener — defaults to `Same`, but if the `HTTPRoute` lives in a different namespace than the `Gateway`, it needs `from: All` or a `Selector`, and the route's `ResolvedRefs` condition will flip to `False` with a clear reason if this is wrong.
- Referencing a `backendRef` Service that doesn't exist or has no matching port — this is exactly what `ResolvedRefs: False` is for; check `kubectl describe httproute` for the reason string instead of guessing.
