set -euo pipefail

```
Lightweight CKNE LLM inference-routing simulation.


This installs:
- Gateway API CRDs
- Gateway API Inference Extension CRDs
- KServe LLMInferenceService CRD only
- lightweight simulated model servers
- lightweight Endpoint Picker (LWEPP)


It deliberately does NOT install:
- KServe controller
- Envoy Gateway / AI Gateway
- cert-manager
- LeaderWorkerSet
- GPU/vLLM infrastructure


The purpose is to exercise the Kubernetes API/resource relationships
relevant to the CKNE without requiring a GPU-backed LLM stack.
```

GATEWAY_API_VERSION="${GATEWAY_API_VERSION:-v1.6.0}"
GIE_VERSION="${GIE_VERSION:-v1.6.2}"
KSERVE_VERSION="${KSERVE_VERSION:-v0.20.0}"
SIMULATOR_IMAGE="${SIMULATOR_IMAGE:-ghcr.io/llm-d/llm-d-inference-sim.7.1}"

echo "==> CKNE LLM inference-routing lightweight simulation"
echo
echo "Gateway API: ${GATEWAY_API_VERSION}"
echo "Inference Extension: ${GIE_VERSION}"
echo "KServe LLMInferenceService: ${KSERVE_VERSION}"
echo

command -v kubectl >/dev/null || {
echo "ERROR: kubectl is required."
exit 1
}

command -v helm >/dev/null || {
echo "ERROR: helm is required."
exit 1
}

echo "==> Checking Kubernetes connectivity"
kubectl cluster-info >/dev/null

echo "==> Installing Gateway API CRDs"
kubectl apply --server-side
-f "https://github.com/kubernetes-sigs/gateway-api/releases/download/${GATEWAY_API_VERSION}/standard-install.yaml"

echo "==> Installing Gateway API Inference Extension CRDs"
kubectl apply --server-side
-f "https://github.com/kubernetes-sigs/gateway-api-inference-extension/releases/download/${GIE_VERSION}/manifests.yaml"

echo "==> Installing KServe LLMInferenceService CRDs only"



```
KServe's current architecture separates the LLMInferenceService CRDs
from the controller/resources chart. We intentionally install only
the CRDs here.
```



helm upgrade --install kserve-llmisvc-crd
oci://ghcr.io/kserve/charts/kserve-llmisvc-crd
--version "${KSERVE_VERSION}"
--namespace kserve
--create-namespace

echo "==> Waiting for CRDs"
kubectl wait
--for=condition=Established
crd/llminferenceservices.serving.kserve.io
--timeout=120s

kubectl wait
--for=condition=Established
crd/inferencepools.inference.networking.k8s.io
--timeout=120s

echo "==> Creating lightweight simulated inference environment"

apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
name: llama-3-8b-route
namespace: default
spec:
parentRefs:
- name: llama-3-8b-gateway
rules:
- matches:
- path:
type: PathPrefix
value: /v1
backendRefs:
- group: inference.networking.k8s.io
kind: InferencePool
name: llama-3-8b-pool
EOF

echo
echo "==> Waiting for simulated model servers"
kubectl rollout status deployment/llama-3-8b --timeout=180s

echo "==> Waiting for lightweight Endpoint Picker"
kubectl rollout status deployment/llama-3-8b-epp --timeout=180s

echo
echo "==> Installed API resources"
kubectl api-resources | grep -Ei 'llminference|inferencepool|gateway|httproute' || true

echo
echo "==> Simulation resources"
kubectl get deployment,service,inferencepool,gateway,httproute

echo
echo "Setup complete."
echo
echo "Next:"
echo " 1. Inspect the installed schemas with kubectl explain."
echo " 2. Create the LLMInferenceService from the task."
echo " 3. Run ./verify.sh"
echo " 4. Test the simulated endpoint with:"
echo " kubectl port-forward svc/llama-3-8b 8080:8000"
echo " curl http://localhost:8080/v1/chat/completions ..."
