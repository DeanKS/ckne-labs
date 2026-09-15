# Scenario: Hubble Metrics and Prometheus Integration

**Domain:** Observability (15%)
**Competencies:** Analyzing Network Health Using Metrics

## Task

1. Enable Hubble with DNS, drop, TCP, flow, and HTTP metrics.
2. Expose those metrics to Prometheus via a `ServiceMonitor`.
3. Enable Bandwidth Manager and confirm — via a metric, not just a Helm flag — that it's actually active in the datapath.

## Success criteria

- `cilium-dbg status` shows Hubble enabled with metrics.
- A Prometheus query for `cilium_feature_adv_connect_and_lb_bandwidth_manager_enabled` returns `1`.
- `hubble observe` shows live L7 HTTP flow data, not just L3/L4.

## Official documentation

- Resource usage monitoring — https://kubernetes.io/docs/tasks/debug/debug-cluster/resource-usage-monitoring/
- Cilium/Hubble metrics — https://docs.cilium.io/en/stable/observability/metrics/
