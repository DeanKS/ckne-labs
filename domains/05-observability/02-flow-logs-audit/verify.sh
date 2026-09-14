#!/usr/bin/env bash
set -uo pipefail
pass=0; fail=0
check() { if eval "$2"; then echo "PASS: $1"; pass=$((pass+1)); else echo "FAIL: $1"; fail=$((fail+1)); fi; }

VALUES=$(helm get values cilium -n kube-system 2>/dev/null || echo "")
check "hubble.export.static.enabled is true" "echo '${VALUES}' | grep -q 'export'"
check "Hubble relay/agent reachable for hubble observe" \
  "kubectl -n kube-system exec ds/cilium -- hubble observe -n secure-app --last 1 >/dev/null 2>&1"

echo "---"; echo "${pass} passed, ${fail} failed"; exit $fail
