#!/usr/bin/env bash
set -euo pipefail
echo "Assumes Cilium is installed without Hubble metrics enabled yet."
echo "Assumes a Prometheus stack (e.g. kube-prometheus-stack) is already running in-cluster."
cilium status 2>/dev/null | grep -i hubble || true

echo
echo "--- Part 2 setup: seeding synthetic dashboard data ---"
echo "Requires Pushgateway reachable at pushgateway:9091 (part of many kube-prometheus-stack installs,"
echo "or run one locally: kubectl run pushgateway --image=prom/pushgateway --port=9091 --expose)"

seed_metric() {
  local service="$1" latency_ms="$2"
  cat << EOF | curl -s --data-binary @- "http://pushgateway:9091/metrics/job/synthetic_latency/service/${service}"
service_latency_ms{service="${service}"} ${latency_ms}
EOF
}

seed_metric frontend 45
seed_metric orders 52
seed_metric payments 890   # deliberately abnormal - this is what Part 2 asks you to find
seed_metric database 38

echo "Synthetic latency data seeded for frontend/orders/payments/database."
echo "One of these four is deliberately abnormal - find it via the dashboard, not this script."
