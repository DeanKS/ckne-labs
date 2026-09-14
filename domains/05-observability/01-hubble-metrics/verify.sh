#!/usr/bin/env bash
set -uo pipefail
pass=0; fail=0
check() { if eval "$2"; then echo "PASS: $1"; pass=$((pass+1)); else echo "FAIL: $1"; fail=$((fail+1)); fi; }

VALUES=$(helm get values cilium -n kube-system 2>/dev/null || echo "")
check "hubble.metrics.enabled includes httpV2" "echo '${VALUES}' | grep -q httpV2"
check "bandwidthManager.enabled is true" "echo '${VALUES}' | grep -q 'bandwidthManager'"
check "Hubble relay deployment exists" "kubectl -n kube-system get deploy hubble-relay >/dev/null 2>&1"

echo "---"; echo "${pass} passed, ${fail} failed"; exit $fail
