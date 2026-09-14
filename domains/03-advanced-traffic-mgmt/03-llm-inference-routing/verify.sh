#!/usr/bin/env bash
set -uo pipefail
pass=0; fail=0
check() { if eval "$2"; then echo "PASS: $1"; pass=$((pass+1)); else echo "FAIL: $1"; fail=$((fail+1)); fi; }

check "LLMInferenceService CRD is installed" \
  "kubectl api-resources | grep -qi llminferenceservice"
check "InferencePool CRD is installed" \
  "kubectl api-resources | grep -qi inferencepool"
check "llm-vllm LLMInferenceService exists (if you deployed it)" \
  "kubectl get llminferenceservice llm-vllm >/dev/null 2>&1"

echo "---"; echo "${pass} passed, ${fail} failed"
echo "Note: full readiness/functional verification of this stack needs GPU-backed nodes"
echo "and is not reproducible in a bare Kind cluster — this check only confirms the CRDs"
echo "and object exist."
exit $fail
