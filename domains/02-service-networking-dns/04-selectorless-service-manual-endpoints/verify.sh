#!/usr/bin/env bash
set -uo pipefail
pass=0; fail=0
check() { if eval "$2"; then echo "PASS: $1"; pass=$((pass+1)); else echo "FAIL: $1"; fail=$((fail+1)); fi; }

check "external-api Service exists with no selector" \
  "[ -z \"\$(kubectl -n svc-lab get svc external-api -o jsonpath='{.spec.selector}' 2>/dev/null)\" ]"
check "manual EndpointSlice exists for external-api" \
  "kubectl -n svc-lab get endpointslices -l kubernetes.io/service-name=external-api -o name | grep -q endpointslice"
check "EndpointSlice carries at least one address" \
  "[ -n \"\$(kubectl -n svc-lab get endpointslices -l kubernetes.io/service-name=external-api -o jsonpath='{.items[0].endpoints[0].addresses[0]}' 2>/dev/null)\" ]"

echo "---"; echo "${pass} passed, ${fail} failed"; exit $fail
