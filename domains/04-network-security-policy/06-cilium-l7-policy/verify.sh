#!/usr/bin/env bash
set -uo pipefail
pass=0; fail=0
check() { if eval "$2"; then echo "PASS: $1"; pass=$((pass+1)); else echo "FAIL: $1"; fail=$((fail+1)); fi; }

check "api-l7-get-only CiliumNetworkPolicy exists" \
  "kubectl -n l7-lab get ciliumnetworkpolicy api-l7-get-only >/dev/null 2>&1"
check "policy has an http rules block" \
  "kubectl -n l7-lab get ciliumnetworkpolicy api-l7-get-only -o yaml | grep -q 'method: GET'"

FRONTEND=$(kubectl -n l7-lab get pod -l app=frontend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -n "${FRONTEND}" ]; then
  GET_CODE=$(kubectl -n l7-lab exec "${FRONTEND}" -- curl -s -o /dev/null -w "%{http_code}" http://api:8080/api/anything 2>/dev/null || echo "000")
  check "GET /api/anything succeeds (got: ${GET_CODE})" "[ '${GET_CODE}' = '200' ]"
  POST_CODE=$(kubectl -n l7-lab exec "${FRONTEND}" -- curl -s -o /dev/null -w "%{http_code}" -X POST http://api:8080/api/anything 2>/dev/null || echo "000")
  check "POST /api/anything is rejected (got: ${POST_CODE}, expect 403)" "[ '${POST_CODE}' = '403' ]"
fi

echo "---"; echo "${pass} passed, ${fail} failed"; exit $fail
