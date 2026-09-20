#!/usr/bin/env bash
set -uo pipefail
pass=0; fail=0
check() { if eval "$2"; then echo "PASS: $1"; pass=$((pass+1)); else echo "FAIL: $1"; fail=$((fail+1)); fi; }

VALUES=$(helm get values cilium -n kube-system 2>/dev/null || echo "")
check "kubeProxyReplacement is true in Helm values" "echo '${VALUES}' | grep -q 'kubeProxyReplacement: true'"
check "hubble.enabled is true" "echo '${VALUES}' | grep -A2 'hubble:' | grep -q 'enabled: true'"
check "all nodes are Ready" "! kubectl get nodes --no-headers | grep -qv Ready"
check "hubble-relay deployment is available" "kubectl -n kube-system get deploy hubble-relay >/dev/null 2>&1"
check "hubble-ui deployment is available" "kubectl -n kube-system get deploy hubble-ui >/dev/null 2>&1"

echo "---"; echo "${pass} passed, ${fail} failed"; exit $fail
