#!/usr/bin/env bash
set -euo pipefail
echo "Assumes Cilium is installed without Hubble metrics enabled yet."
echo "Assumes a Prometheus stack (e.g. kube-prometheus-stack) is already running in-cluster."
cilium status 2>/dev/null | grep -i hubble || true
