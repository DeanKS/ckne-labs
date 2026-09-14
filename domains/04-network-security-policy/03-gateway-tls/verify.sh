#!/usr/bin/env bash
set -uo pipefail
pass=0; fail=0
check() { if eval "$2"; then echo "PASS: $1"; pass=$((pass+1)); else echo "FAIL: $1"; fail=$((fail+1)); fi; }

check "public-gw has an https listener on 443" \
  "kubectl -n gw-lab get gateway public-gw -o jsonpath='{.spec.listeners[?(@.name==\"https\")].port}' | grep -q 443"
check "orders-tls Secret exists" \
  "kubectl -n gw-lab get secret orders-tls >/dev/null 2>&1"
check "BackendTLSPolicy orders-v2-backend-tls exists" \
  "kubectl -n gw-lab get backendtlspolicy orders-v2-backend-tls >/dev/null 2>&1"
check "orders-v2-sa cannot list secrets cluster-wide" \
  "! kubectl auth can-i list secrets --as=system:serviceaccount:gw-lab:orders-v2-sa -A | grep -q yes"
check "orders-v2-sa CAN read configmaps in gw-lab" \
  "kubectl auth can-i get configmaps --as=system:serviceaccount:gw-lab:orders-v2-sa -n gw-lab | grep -q yes"

echo "---"; echo "${pass} passed, ${fail} failed"; exit $fail
