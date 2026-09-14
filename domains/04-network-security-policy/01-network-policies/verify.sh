#!/usr/bin/env bash
set -uo pipefail
pass=0; fail=0
check() { if eval "$2"; then echo "PASS: $1"; pass=$((pass+1)); else echo "FAIL: $1"; fail=$((fail+1)); fi; }

check "default-deny-all NetworkPolicy exists" \
  "kubectl -n secure-app get networkpolicy default-deny-all >/dev/null 2>&1"
check "allow-frontend-to-backend exists" \
  "kubectl -n secure-app get networkpolicy allow-frontend-to-backend >/dev/null 2>&1"
check "allow-backend-to-db exists" \
  "kubectl -n secure-app get networkpolicy allow-backend-to-db >/dev/null 2>&1"
check "allow-dns-egress exists" \
  "kubectl -n secure-app get networkpolicy allow-dns-egress >/dev/null 2>&1"
check "allow-external-to-frontend exists" \
  "kubectl -n secure-app get networkpolicy allow-external-to-frontend >/dev/null 2>&1"

FRONTEND_POD=$(kubectl -n secure-app get pod -l app=frontend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "${FRONTEND_POD:-}" ]; then
  DB_IP=$(kubectl -n secure-app get svc db -o jsonpath='{.spec.clusterIP}' 2>/dev/null || echo "10.0.0.1")
  check "frontend CANNOT reach db directly (expected to time out / fail)" \
    "! kubectl -n secure-app exec ${FRONTEND_POD} -- sh -c 'wget -T 3 -q -O- http://${DB_IP} 2>&1' >/dev/null 2>&1"
fi

echo "---"; echo "${pass} passed, ${fail} failed"; exit $fail
