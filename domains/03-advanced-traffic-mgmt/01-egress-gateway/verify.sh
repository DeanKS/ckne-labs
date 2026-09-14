#!/usr/bin/env bash
set -uo pipefail
pass=0; fail=0
check() { if eval "$2"; then echo "PASS: $1"; pass=$((pass+1)); else echo "FAIL: $1"; fail=$((fail+1)); fi; }

check "CiliumEgressGatewayPolicy egress-external-api exists" \
  "kubectl get ciliumegressgatewaypolicy egress-external-api >/dev/null 2>&1"
check "policy targets 203.0.113.0/24" \
  "kubectl get ciliumegressgatewaypolicy egress-external-api -o jsonpath='{.spec.destinationCIDRs[0]}' | grep -q '203.0.113.0/24'"
check "policy egressIP is 10.168.60.100" \
  "kubectl get ciliumegressgatewaypolicy egress-external-api -o jsonpath='{.spec.egressGateway.egressIP}' | grep -q '10.168.60.100'"
check "gateway node is labeled egress-node=true" \
  "kubectl get node ckne-labs-worker -o jsonpath='{.metadata.labels.egress-node}' | grep -q true"

echo "---"; echo "${pass} passed, ${fail} failed"; exit $fail
