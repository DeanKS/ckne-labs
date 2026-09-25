#!/usr/bin/env bash
set -uo pipefail
pass=0; fail=0
check() { if eval "$2"; then echo "PASS: $1"; pass=$((pass+1)); else echo "FAIL: $1"; fail=$((fail+1)); fi; }

check "Multus daemonset is available" \
  "kubectl -n kube-system get ds kube-multus-ds >/dev/null 2>&1"
check "storage-net NetworkAttachmentDefinition exists" \
  "kubectl -n default get network-attachment-definitions storage-net >/dev/null 2>&1"
check "dual-homed-pod has a net1 interface with 192.168.100.x address" \
  "kubectl -n default exec dual-homed-pod -- ip addr show net1 2>/dev/null | grep -q '192\.168\.100\.'"

echo "---"; echo "${pass} passed, ${fail} failed"; exit $fail
