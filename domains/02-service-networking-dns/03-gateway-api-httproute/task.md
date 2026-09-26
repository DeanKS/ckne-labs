# Scenario: Gateway API Path- and Header-Based Routing

**Domain:** Service Networking and DNS (25%)
**Competencies:** Managing Traffic with the Gateway API (Gateway, HTTPRoutes)

## Context

Two Services exist in namespace `gw-lab`: `orders-v1` and `orders-v2`, both serving HTTP on port 80. A `GatewayClass` is already installed.

## Task

1. Create a `Gateway` named `public-gw` listening on HTTP port 80.
2. Create an `HTTPRoute` named `orders-route` attached to `public-gw` such that:
   - Requests to path prefix `/orders` with header `x-canary: true` go to `orders-v2`.
   - All other requests to `/orders` go to `orders-v1`.
3. Do this without an `Ingress` resource - Gateway API only.

## Success criteria

- `curl -H "x-canary: true" <gw-ip>/orders` is served by `orders-v2`.
- `curl <gw-ip>/orders` (no header) is served by `orders-v1`.
- The `HTTPRoute` shows `Accepted: True` and `ResolvedRefs: True` in its status conditions.

## Official documentation

- Gateway API concept - https://kubernetes.io/docs/concepts/services-networking/gateway/
- HTTPRoute reference - https://gateway-api.sigs.k8s.io/reference/api-types/httproute/
- Ingress (for contrast with Gateway API) - https://kubernetes.io/docs/concepts/services-networking/ingress/
