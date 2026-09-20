#!/usr/bin/env bash
set -uo pipefail
pass=0; fail=0
check() { if eval "$2"; then echo "PASS: $1"; pass=$((pass+1)); else echo "FAIL: $1"; fail=$((fail+1)); fi; }

check "cert-manager is installed and running" \
  "kubectl -n cert-manager get deployment cert-manager >/dev/null 2>&1"
check "selfsigned-issuer ClusterIssuer exists" \
  "kubectl get clusterissuer selfsigned-issuer >/dev/null 2>&1"
check "orders-tls-managed Certificate is Ready" \
  "kubectl -n gw-lab get certificate orders-tls-managed -o jsonpath='{.status.conditions[?(@.type==\"Ready\")].status}' | grep -q True"
check "public-gw https listener references orders-tls-managed" \
  "kubectl -n gw-lab get gateway public-gw -o jsonpath='{.spec.listeners[?(@.name==\"https\")].tls.certificateRefs[0].name}' | grep -q orders-tls-managed"

echo "---"; echo "${pass} passed, ${fail} failed"; exit $fail
