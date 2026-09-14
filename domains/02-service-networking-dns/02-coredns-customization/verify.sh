#!/usr/bin/env bash
set -uo pipefail
pass=0; fail=0
check() { if eval "$2"; then echo "PASS: $1"; pass=$((pass+1)); else echo "FAIL: $1"; fail=$((fail+1)); fi; }

CF=$(kubectl -n kube-system get cm coredns -o jsonpath='{.data.Corefile}')
check "Corefile has an ext-ai.com server block" "echo \"\${CF}\" | grep -q 'ext-ai.com:53'"
check "ext-ai.com block forwards to 1.1.1.1" "echo \"\${CF}\" | grep -A3 'ext-ai.com:53' | grep -q 'forward . 1.1.1.1'"
check "default .:53 block still has the kubernetes plugin" "echo \"\${CF}\" | grep -q 'kubernetes cluster.local'"

echo "---"; echo "${pass} passed, ${fail} failed"; exit $fail
