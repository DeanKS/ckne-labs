#!/usr/bin/env bash
set -uo pipefail
pass=0; fail=0
check() { if eval "$2"; then echo "PASS: $1"; pass=$((pass+1)); else echo "FAIL: $1"; fail=$((fail+1)); fi; }

check "public-gw Gateway exists" "kubectl -n gw-lab get gateway public-gw >/dev/null 2>&1"
check "orders-route HTTPRoute exists" "kubectl -n gw-lab get httproute orders-route >/dev/null 2>&1"
ACCEPTED=$(kubectl -n gw-lab get httproute orders-route -o jsonpath='{.status.parents[0].conditions[?(@.type=="Accepted")].status}' 2>/dev/null)
check "HTTPRoute Accepted=True" "[ \"${ACCEPTED}\" = True ]"
RESOLVED=$(kubectl -n gw-lab get httproute orders-route -o jsonpath='{.status.parents[0].conditions[?(@.type=="ResolvedRefs")].status}' 2>/dev/null)
check "HTTPRoute ResolvedRefs=True" "[ \"${RESOLVED}\" = True ]"

echo "---"; echo "${pass} passed, ${fail} failed"; exit $fail
