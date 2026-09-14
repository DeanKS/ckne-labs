#!/usr/bin/env bash
set -euo pipefail
echo "Assumes Hubble is enabled (see domains/05-observability/01-hubble-metrics)."
echo "Generating some traffic that Domain 4's NetworkPolicy set will deny, for you to find:"
FRONTEND=$(kubectl -n secure-app get pod -l app=frontend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -n "${FRONTEND}" ]; then
  kubectl -n secure-app exec "${FRONTEND}" -- sh -c 'wget -T 2 -q -O- http://db 2>&1 || true' &
fi
echo "Denied traffic generated (frontend -> db, which should be blocked)."
