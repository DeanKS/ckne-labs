#!/usr/bin/env bash
set -uo pipefail

pass=0
fail=0

check() {
if eval "$2"; then
echo "PASS: $1"
pass=$((pass + 1))
else
echo "FAIL: $1"
fail=$((fail + 1))
fi
}

echo "==> CKNE LLM inference-routing simulation verification"
echo

# ---------------------------------------------------------------------------

# CRDs / APIs

# ---------------------------------------------------------------------------

check "LLMInferenceService CRD is installed" 
"kubectl api-resources | grep -qi '^llminferenceservices.*serving.kserve.io'"

check "InferencePool CRD is installed" 
"kubectl api-resources | grep -qi '^inferencepools.*inference.networking.k8s.io'"

check "Gateway API HTTPRoute is installed" 
"kubectl api-resources | grep -qi '^httproutes.*gateway.networking.k8s.io'"

# ---------------------------------------------------------------------------

# Candidate-created LLMInferenceService

# ---------------------------------------------------------------------------

check "llama-3-8b LLMInferenceService exists" 
"kubectl get llminferenceservice llama-3-8b >/dev/null 2>&1"

check "LLMInferenceService uses the expected model" 
"kubectl get llminferenceservice llama-3-8b -o jsonpath='{.spec.model.uri}' | grep -q 'Llama-3.1-8B-Instruct'"

check "LLMInferenceService requests three replicas" 
"test "$(kubectl get llminferenceservice llama-3-8b -o jsonpath='{.spec.replicas}')" = '3'"

check "LLMInferenceService has router configuration" 
"kubectl get llminferenceservice llama-3-8b -o jsonpath='{.spec.router}' | grep -q 'scheduler'"

check "LLMInferenceService scheduler references the simulation pool" 
"kubectl get llminferenceservice llama-3-8b -o jsonpath='{.spec.router.scheduler.pool.ref.name}' | grep -q '^llama-3-8b-pool$'"

# ---------------------------------------------------------------------------

# Simulated inference data plane

# ---------------------------------------------------------------------------

check "Simulated model deployment exists" 
"kubectl get deployment llama-3-8b >/dev/null 2>&1"

check "Three simulated model replicas are ready" 
"test "$(kubectl get deployment llama-3-8b -o jsonpath='{.status.readyReplicas}')" = '3'"

check "Simulated model service exists" 
"kubectl get service llama-3-8b >/dev/null 2>&1"

# ---------------------------------------------------------------------------

# InferencePool / Endpoint Picker

# ---------------------------------------------------------------------------

check "InferencePool exists" 
"kubectl get inferencepool llama-3-8b-pool >/dev/null 2>&1"

check "InferencePool selects the model pods" 
"kubectl get inferencepool llama-3-8b-pool -o jsonpath='{.spec.selector.matchLabels.app}' | grep -q '^llama-3-8b$'"

check "InferencePool targets model port 8000" 
"kubectl get inferencepool llama-3-8b-pool -o jsonpath='{.spec.targetPorts[0].number}' | grep -q '^8000$'"

check "InferencePool references the Endpoint Picker" 
"kubectl get inferencepool llama-3-8b-pool -o jsonpath='{.spec.endpointPickerRef.name}' | grep -q '^llama-3-8b-epp$'"

check "Endpoint Picker deployment exists" 
"kubectl get deployment llama-3-8b-epp >/dev/null 2>&1"

check "Endpoint Picker is ready" 
"test "$(kubectl get deployment llama-3-8b-epp -o jsonpath='{.status.readyReplicas}')" = '1'"

check "Endpoint Picker service exists" 
"kubectl get service llama-3-8b-epp >/dev/null 2>&1"

# ---------------------------------------------------------------------------

# Gateway API configuration

# ---------------------------------------------------------------------------

check "Simulation Gateway exists" 
"kubectl get gateway llama-3-8b-gateway >/dev/null 2>&1"

check "HTTPRoute exists" 
"kubectl get httproute llama-3-8b-route >/dev/null 2>&1"

check "HTTPRoute references the InferencePool" 
"kubectl get httproute llama-3-8b-route -o jsonpath='{.spec.rules[0].backendRefs[0].name}' | grep -q '^llama-3-8b-pool$'"

check "HTTPRoute uses the InferencePool API group" 
"kubectl get httproute llama-3-8b-route -o jsonpath='{.spec.rules[0].backendRefs[0].group}' | grep -q '^inference.networking.k8s.io$'"

# ---------------------------------------------------------------------------

# OpenAI-compatible endpoint

# ---------------------------------------------------------------------------

echo
echo "==> Testing simulated OpenAI-compatible endpoint"

kubectl port-forward svc/llama-3-8b 18080:8000 >/tmp/ckne-llm-port-forward.log 2>&1 &
PF_PID=$!

cleanup() {
kill "${PF_PID}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

sleep 3

RESPONSE="$(curl -sS --max-time 10 
-X POST 
http://127.0.0.1:18080/v1/chat/completions 
-H 'Content-Type: application/json' 
-d '{
"model": "meta-llama/Llama-3.1-8B-Instruct",
"messages": [
{
"role": "user",
"content": "CKNE routing test"
}
]
}' 2>/dev/null || true)"

if [ -n "${RESPONSE}" ]; then
echo "PASS: /v1/chat/completions returned a response"
pass=$((pass + 1))
else
echo "FAIL: /v1/chat/completions did not return a response"
fail=$((fail + 1))
fi

echo
echo "---"
echo "${pass} passed, ${fail} failed"
echo
echo "NOTE:"
echo "This is a lightweight CKNE simulation."
echo "The KServe controller is intentionally NOT installed."
echo "Therefore LLMInferenceService Ready=True is not expected."
echo "The verification checks the real CRD/schema and the simulated"
echo "InferencePool/EPP/Gateway API architecture instead."
echo

exit "${fail}"

