#!/usr/bin/env bash
set -uo pipefail
pass=0; fail=0
check() { if eval "$2"; then echo "PASS: $1"; pass=$((pass+1)); else echo "FAIL: $1"; fail=$((fail+1)); fi; }

check "sample-access.log exists" "[ -f sample-access.log ]"
check "log contains at least one 404 entry" "grep -q 'status=404' sample-access.log"
check "log contains at least one 502 entry" "grep -q 'status=502' sample-access.log"
check "log contains the probing source 198.51.100.9 five times" \
  "[ \$(grep -c '198.51.100.9' sample-access.log) -eq 5 ]"
check "req_id a1c0 is the slowest logged entry (latency_ms=3004)" \
  "grep 'req_id=a1c0' sample-access.log | grep -q 'latency_ms=3004'"

echo "---"; echo "${pass} passed, ${fail} failed"
echo "Note: this scenario is primarily a reading/analysis exercise - the checks above only"
echo "confirm the sample log is intact, not that you correctly interpreted it."
exit $fail
