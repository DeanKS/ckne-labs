#!/usr/bin/env bash
set -uo pipefail
pass=0; fail=0
check() { if eval "$2"; then echo "PASS: $1"; pass=$((pass+1)); else echo "FAIL: $1"; fail=$((fail+1)); fi; }

check "cni0 exists on worker node" \
  "docker exec ckne-labs-worker ip link show cni0 >/dev/null 2>&1"
check "cni-test-pod is Running" \
  "[ \"\$(kubectl get pod cni-test-pod -o jsonpath='{.status.phase}' 2>/dev/null)\" = Running ]"
POD_IP=$(kubectl get pod cni-test-pod -o jsonpath='{.status.podIP}' 2>/dev/null || echo "")
check "pod IP is in 10.1.0.0/16 (got: ${POD_IP:-none})" \
  "echo '${POD_IP}' | grep -qE '^10\.1\.'"

echo "---"; echo "${pass} passed, ${fail} failed"; exit $fail
