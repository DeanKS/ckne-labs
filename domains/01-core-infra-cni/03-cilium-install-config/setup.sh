#!/usr/bin/env bash
set -euo pipefail
echo "Assumes a fresh Kind cluster with disableDefaultCNI: true (see ../../kind-config.yaml)."
echo "Simulating a colleague's broken install attempt (kube-proxy replacement and Hubble both off):"
cilium install --set kubeProxyReplacement=false --set hubble.enabled=false 2>&1 || true
echo
echo "Cluster is now in a partially-configured state. Fix it per task.md."
