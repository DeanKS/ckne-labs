# Scenario: Custom CoreDNS Forwarding for an External Domain

**Domain:** Service Networking and DNS (25%)
**Competencies:** Customizing CoreDNS for Services · Troubleshooting Service Network Traffic

## Task

An external service is only resolvable via the corporate resolver at `1.1.1.1`, under the zone `ext-ai.com`. Cluster-internal DNS (`cluster.local`, Services) must keep working exactly as before.

Configure CoreDNS so that:

1. Any query for `*.ext-ai.com` is forwarded to `1.1.1.1` specifically.
2. All other queries continue to resolve exactly as they do today (cluster Services, `/etc/resolv.conf` upstream for other external names).
3. Your change survives a CoreDNS pod restart (i.e. it's in the ConfigMap, not a live edit).

## Success criteria

- `dig ext-ai.com` from inside a pod returns a real answer via `1.1.1.1`.
- `dig kubernetes.default.svc.cluster.local` still resolves the API server ClusterIP.
- `dig google.com` (or another ordinary external name) still resolves via the default upstream.
