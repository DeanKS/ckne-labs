#!/usr/bin/env bash
set -euo pipefail
echo "This lab assumes KServe v0.16+ (with LLMInferenceService CRD) and the Gateway API"
echo "Inference Extension CRDs (InferencePool) are already installed - installing the full"
echo "stack (vLLM images, GPU scheduling, Envoy AI Gateway) is out of scope for a local Kind"
echo "lab. Use this scenario to understand the architecture and the CRDs, not to fully"
echo "reproduce a GPU-backed deployment on a laptop."
echo
kubectl api-resources | grep -i llminferenceservice || echo "LLMInferenceService CRD not found - install KServe v0.16+ first."
