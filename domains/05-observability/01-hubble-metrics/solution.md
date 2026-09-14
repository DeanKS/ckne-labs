# Solution: Hubble Metrics + Prometheus

## Enable metrics

```bash
helm upgrade cilium cilium/cilium \
  --namespace kube-system \
  --reuse-values \
  --set hubble.metrics.enabled="{dns,drop,tcp,flow,httpV2}" \
  --set hubble.metrics.serviceMonitor.enabled=true \
  --set bandwidthManager.enabled=true

kubectl -n kube-system rollout restart ds/cilium
kubectl -n kube-system rollout restart deployment/hubble-relay
```

`httpV2` specifically (not the older `http` metric) is what gives you per-method, per-status-code HTTP breakdown — using the older name is a common way to end up with metrics that technically exist but don't have the granularity a real troubleshooting question expects.

## Confirm Bandwidth Manager is really active — not just "the flag is set"

Helm succeeding only tells you Cilium accepted the setting; it doesn't confirm the eBPF datapath actually turned the feature on (e.g. it silently no-ops on unsupported kernels). The feature-enablement metrics exist exactly to close that gap:

```bash
kubectl exec -n monitoring deploy/prometheus-server -- \
  curl -s 'http://localhost:9090/api/v1/query?query=cilium_feature_adv_connect_and_lb_bandwidth_manager_enabled' \
  | grep '"1"'
```

A result of `1` per-node confirms the datapath itself reports the feature live, not merely configured.

## Confirm L7 visibility

```bash
kubectl -n kube-system exec ds/cilium -- hubble observe --protocol http -f
```

While generating some HTTP traffic to a Service in the cluster, you should see per-request lines with method, path, and status code — this is what standard `kubectl top`/node-level metrics can't give you, since those only see resource consumption, not the L7 semantics inside the traffic.

## Common failure modes

- Checking `hubble.enabled=true` alone and assuming metrics come with it — Hubble the observability platform and Hubble *metrics* export are separate flags; you need `hubble.metrics.enabled` explicitly.
- Forgetting `hubble.metrics.serviceMonitor.enabled=true` when Prometheus Operator is in use — without it, the metrics endpoint exists on the Cilium pods but nothing tells Prometheus to scrape it, and the query returns no data, which looks identical to "the feature isn't enabled" if you don't separately check `cilium-dbg status`.
- Reading `cilium status` (no metrics) instead of the feature-gate metric when asked to prove Bandwidth Manager is active — the exam competency is explicitly "Analyzing Network Health Using Metrics," so a status-only check under-answers the question even if it happens to be true.
