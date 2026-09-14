#!/usr/bin/env bash
set -uo pipefail
pass=0; fail=0
check() { if eval "$2"; then echo "PASS: $1"; pass=$((pass+1)); else echo "FAIL: $1"; fail=$((fail+1)); fi; }

STATUS=$(kubectl -n kube-system exec ds/cilium -- cilium-dbg status 2>/dev/null | grep -i encryption || echo "")
check "cilium-dbg status reports Wireguard encryption" \
  "echo '${STATUS}' | grep -qi wireguard"
check "cilium-dbg status reports NodeEncryption Enabled" \
  "echo '${STATUS}' | grep -qi 'Enabled'"

echo "---"; echo "${pass} passed, ${fail} failed"; exit $fail
