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

`httpV2` specifically (not the older `http` metric) is what gives you per-method, per-status-code HTTP breakdown - using the older name is a common way to end up with metrics that technically exist but don't have the granularity a real troubleshooting question expects.

## Confirm Bandwidth Manager is really active - not just "the flag is set"

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

While generating some HTTP traffic to a Service in the cluster, you should see per-request lines with method, path, and status code - this is what standard `kubectl top`/node-level metrics can't give you, since those only see resource consumption, not the L7 semantics inside the traffic.

## Part 2: Reading the dashboard without writing PromQL from scratch

The metric name is already given to you: `service_latency_ms{service="..."}`. In a real dashboard (Grafana panel, or Prometheus's own expression browser), you'd typically just select it from a dropdown or click into a pre-built panel - the skill being tested is reading and comparing values across labels, not authoring the query.

```bash
curl -s 'http://pushgateway:9091/metrics' | grep service_latency_ms
```

`payments` is the outlier - its latency is roughly 17-20x every other service in this synthetic set, which is a "sustained shift," not what a single transient spike would look like in a real time series (a real dashboard would show this as a step-change or sustained plateau on the graph rather than one spike surrounded by normal values - this synthetic setup only gives you one point in time, so in a live exam environment the actual next step would be checking whether the elevated value persists across a time range, not just at one instant).

The point of this exercise isn't the number itself - it's the habit of scanning across labels/services for the one that doesn't match its peers, which is exactly what a real dashboard full of unfamiliar metrics rewards over trying to recall a specific PromQL function under time pressure.

## Common failure modes

- Checking `hubble.enabled=true` alone and assuming metrics come with it - Hubble the observability platform and Hubble *metrics* export are separate flags; you need `hubble.metrics.enabled` explicitly.
- Forgetting `hubble.metrics.serviceMonitor.enabled=true` when Prometheus Operator is in use - without it, the metrics endpoint exists on the Cilium pods but nothing tells Prometheus to scrape it, and the query returns no data, which looks identical to "the feature isn't enabled" if you don't separately check `cilium-dbg status`.
- Reading `cilium status` (no metrics) instead of the feature-gate metric when asked to prove Bandwidth Manager is active - the exam competency is explicitly "Analyzing Network Health Using Metrics," so a status-only check under-answers the question even if it happens to be true.
