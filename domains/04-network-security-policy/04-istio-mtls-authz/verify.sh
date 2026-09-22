#!/usr/bin/env bash
set -uo pipefail
pass=0; fail=0
check() { if eval "$2"; then echo "PASS: $1"; pass=$((pass+1)); else echo "FAIL: $1"; fail=$((fail+1)); fi; }

check "PeerAuthentication 'default' exists in mesh-lab with STRICT mode" \
  "kubectl -n mesh-lab get peerauthentication default -o jsonpath='{.spec.mtls.mode}' | grep -q STRICT"
check "AuthorizationPolicy payments-allow-frontend-only exists" \
  "kubectl -n mesh-lab get authorizationpolicy payments-allow-frontend-only >/dev/null 2>&1"
check "AuthorizationPolicy references frontend-sa principal" \
  "kubectl -n mesh-lab get authorizationpolicy payments-allow-frontend-only -o yaml | grep -q 'frontend-sa'"

echo "---"; echo "${pass} passed, ${fail} failed"
echo "Note: full mTLS/authz behavior verification requires a running Istio mesh with sidecars"
echo "injected - this check only confirms the policy objects exist and are shaped correctly."
exit $fail
