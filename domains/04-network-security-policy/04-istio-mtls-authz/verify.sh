#!/usr/bin/env bash
set -uo pipefail

NAMESPACE="mesh-lab"

pass=0
fail=0

###############################################################################
# Result helpers
###############################################################################

pass_check() {
  echo "PASS: $1"
  pass=$((pass + 1))
}

fail_check() {
  echo "FAIL: $1"
  fail=$((fail + 1))
}

run_check() {
  description="$1"
  function_name="$2"

  if "$function_name"; then
    pass_check "$description"
  else
    fail_check "$description"
  fi
}

###############################################################################
# PeerAuthentication
###############################################################################

check_strict_mtls() {
  kubectl -n "$NAMESPACE" get peerauthentication \
    -o jsonpath='{range .items[*]}{.spec.mtls.mode}{"\n"}{end}' \
    2>/dev/null |
    grep -Fxq "STRICT"
}

###############################################################################
# AuthorizationPolicy discovery
#
# We deliberately do NOT require a particular metadata.name.
#
# The policy must:
#   - select app=payments
#   - use ALLOW
#   - contain the frontend service-account principal
###############################################################################

find_payments_policy() {
  kubectl -n "$NAMESPACE" get authorizationpolicy \
    -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' \
    2>/dev/null
}

get_payments_policy() {
  find_payments_policy |
    while read -r name; do

      selector="$(
        kubectl -n "$NAMESPACE" get authorizationpolicy "$name" \
          -o jsonpath='{.spec.selector.matchLabels.app}' \
          2>/dev/null
      )"

      if [[ "$selector" == "payments" ]]; then
        echo "$name"
        exit 0
      fi

    done
}

check_payments_policy_exists() {
  policy="$(get_payments_policy)"

  [[ -n "$policy" ]]
}

check_payments_selector() {
  policy="$(get_payments_policy)"

  [[ -n "$policy" ]] || return 1

  selector="$(
    kubectl -n "$NAMESPACE" get authorizationpolicy "$policy" \
      -o jsonpath='{.spec.selector.matchLabels.app}' \
      2>/dev/null
  )"

  [[ "$selector" == "payments" ]]
}

check_payments_allow() {
  policy="$(get_payments_policy)"

  [[ -n "$policy" ]] || return 1

  action="$(
    kubectl -n "$NAMESPACE" get authorizationpolicy "$policy" \
      -o jsonpath='{.spec.action}' \
      2>/dev/null
  )"

  # Istio's default action is ALLOW when action is omitted.
  [[ -z "$action" || "$action" == "ALLOW" ]]
}

check_frontend_principal() {
  policy="$(get_payments_policy)"

  [[ -n "$policy" ]] || return 1

  principal="cluster.local/ns/${NAMESPACE}/sa/frontend-sa"

  kubectl -n "$NAMESPACE" get authorizationpolicy "$policy" \
    -o jsonpath='{.spec.rules[*].from[*].source.principals[*]}' \
    2>/dev/null |
    tr ' ' '\n' |
    grep -Fxq "$principal"
}

check_no_namespace_wide_allow() {
  policy="$(get_payments_policy)"

  [[ -n "$policy" ]] || return 1

  namespace_rule="$(
    kubectl -n "$NAMESPACE" get authorizationpolicy "$policy" \
      -o jsonpath='{.spec.rules[*].from[*].source.namespaces[*]}' \
      2>/dev/null
  )"

  [[ -z "$namespace_rule" ]]
}

###############################################################################
# Verification
###############################################################################

echo "=============================================="
echo " Istio Ambient mTLS/AuthZ Verification"
echo "=============================================="
echo

echo "==> PeerAuthentication"

run_check \
  "A PeerAuthentication enables STRICT mTLS in mesh-lab" \
  check_strict_mtls

echo
echo "==> AuthorizationPolicy"

run_check \
  "An AuthorizationPolicy targets the payments workload" \
  check_payments_policy_exists

run_check \
  "The payments AuthorizationPolicy selects app=payments" \
  check_payments_selector

run_check \
  "The payments AuthorizationPolicy uses ALLOW semantics" \
  check_payments_allow

run_check \
  "The payments AuthorizationPolicy allows frontend-sa" \
  check_frontend_principal

run_check \
  "The payments AuthorizationPolicy does not allow the entire mesh-lab namespace" \
  check_no_namespace_wide_allow

###############################################################################
# Summary
###############################################################################

echo
echo "---"
echo "${pass} passed, ${fail} failed"

if [[ "$fail" -eq 0 ]]; then
  echo
  echo "All mTLS and authorization policy checks passed."
else
  echo
  echo "One or more mTLS/authz checks failed."
fi

exit "$fail"
