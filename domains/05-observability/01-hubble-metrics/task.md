# Scenario: Hubble Metrics and Prometheus Integration

**Domain:** Observability (15%)
**Competencies:** Analyzing Network Health Using Metrics

## Task

1. Enable Hubble with DNS, drop, TCP, flow, and HTTP metrics.
2. Expose those metrics to Prometheus via a `ServiceMonitor`.
3. Enable Bandwidth Manager and confirm - via a metric, not just a Helm flag - that it's actually active in the datapath.

## Success criteria

- `cilium-dbg status` shows Hubble enabled with metrics.
- A Prometheus query for `cilium_feature_adv_connect_and_lb_bandwidth_manager_enabled` returns `1`.
- `hubble observe` shows live L7 HTTP flow data, not just L3/L4.

## Part 2: Diagnose the dashboard (no PromQL memorization required)

Real beta-exam feedback (`docs/exam-strategy.md`) says the actual exam environment was UI-driven - Prometheus/Grafana already there for you to read, not something you were expected to query from scratch with hand-written PromQL. This part practices that reading skill directly.

`setup.sh` seeds four services' worth of synthetic latency data into Pushgateway (`frontend`, `orders`, `payments`, `database`). Using only a Prometheus dashboard or `promtool query instant` against the already-running metric (no need to write a new query from scratch - the metric name is given to you, exactly as an exam dashboard would present it), answer:

- Which one of the four services is exhibiting abnormal latency?
- Is that abnormality visible as a sustained shift or a spike? (Check more than one timestamp before answering.)

## Official documentation

- Resource usage monitoring - https://kubernetes.io/docs/tasks/debug/debug-cluster/resource-usage-monitoring/
- Cilium/Hubble metrics - https://docs.cilium.io/en/stable/observability/metrics/
