# Solution / Concept Walkthrough: LLM-Aware Traffic Routing

## 1. Start with the installed API, not memorised YAML

The first step should be to inspect what the cluster actually provides:

```bash
kubectl api-resources | grep -Ei 'llminference|inferencepool|gateway|httproute'
```

Then:

```bash
kubectl explain llminferenceservice.spec
kubectl explain llminferenceservice.spec.router
kubectl explain llminferenceservice.spec.router.scheduler
```

This matters because the LLM inference APIs are evolving rapidly.

The current KServe API continues to expose:

```text
serving.kserve.io/v1alpha1
```

for `LLMInferenceService`, while newer KServe releases also support additional API versions internally. The correct exam technique is therefore to inspect the installed schema rather than assume that an example from documentation or a previous exam environment is still correct.

---

# 2. The important resources

The architecture can be simplified to:

```text
                    Client
                       │
                       ▼
                Gateway / HTTPRoute
                       │
                       ▼
                 InferencePool
                       │
                       ▼
                Endpoint Picker
                       │
             ┌─────────┼─────────┐
             ▼         ▼         ▼
          Pod 1      Pod 2      Pod 3
          vLLM       vLLM       vLLM
```

The responsibilities are different.

### LLMInferenceService

KServe's top-level API for generative inference workloads.

It describes the model and routing configuration.

### Gateway / HTTPRoute

The standard Gateway API layer handles network-level and HTTP-level routing.

An `HTTPRoute` can use an `InferencePool` as a backend rather than an ordinary Kubernetes Service.

### InferencePool

An `InferencePool` represents a group of inference Pods.

For example:

```yaml
apiVersion: inference.networking.k8s.io/v1
kind: InferencePool
metadata:
  name: llama-3-8b-pool
spec:
  selector:
    matchLabels:
      app: llama-3-8b
  targetPorts:
    - number: 8000
  endpointPickerRef:
    name: llama-3-8b-epp
    port:
      number: 9002
    failureMode: FailOpen
```

The current Inference Extension API defines `selector`, `targetPorts`, and `endpointPickerRef` as the key parts of an `InferencePool`.

### Endpoint Picker

The Endpoint Picker is the inference-aware routing extension.

It can consider information about the inference endpoints rather than treating them as identical web-server replicas.

The current Gateway API Inference Extension project provides a lightweight EPP specifically for conformance/testing scenarios.

Production deployments may use a more sophisticated EPP implementation such as the components now being developed in the `llm-d` ecosystem.

---

# 3. Candidate LLMInferenceService

For this simulation, the important part is that the LLMInferenceService references the existing simulation pool.

A suitable configuration is:

```yaml
apiVersion: serving.kserve.io/v1alpha1
kind: LLMInferenceService
metadata:
  name: llama-3-8b
  namespace: default
spec:
  model:
    uri: hf://meta-llama/Llama-3.1-8B-Instruct
    name: meta-llama/Llama-3.1-8B-Instruct

  replicas: 3

  router:
    route: {}
    scheduler:
      pool:
        ref:
          name: llama-3-8b-pool
```

The important difference from the original version is:

```yaml
scheduler:
  pool:
    ref:
      name: llama-3-8b-pool
```

rather than simply:

```yaml
scheduler: {}
```

With a real KServe controller, an empty scheduler tells KServe to provision/manage the scheduler and its pool. Current KServe documentation also supports referencing an existing pool, in which case the controller uses that pool rather than creating another one.

That makes the referenced-pool form particularly useful for this lightweight simulation.

---

# 4. Why ordinary round-robin is insufficient

Imagine a conversation:

```text
Turn 1:
"Explain Kubernetes NetworkPolicy"

Turn 2:
"Now compare that with CiliumNetworkPolicy"
```

The second request contains a large amount of context derived from the first request.

An LLM processes that context using attention mechanisms. The resulting attention state can be retained as a KV-cache.

Conceptually:

```text
                    Turn 1
                      │
                      ▼
                   Pod A
                      │
                 KV-cache A
                      │
                      │
                    Turn 2
                      │
             ┌────────┴────────┐
             │                 │
          Pod A             Pod B
             │                 │
       cache available     cache absent
             │                 │
          reuse            recompute
```

If the second request is sent to Pod A, the model server may be able to reuse useful cached state.

If it is sent to Pod B, Pod B may have to process the shared prefix again.

Therefore the routing decision is not simply:

```text
request 1 → pod A
request 2 → pod B
request 3 → pod C
```

Instead, the inference gateway/EPP can use inference-specific information when selecting a backend.

Current Gateway API Inference Extension documentation explicitly describes the EPP as using endpoint information such as KV-cache utilization and queue length to make routing decisions.

---

# 5. Why InferencePool is not just a Service

A Kubernetes Service primarily provides:

```text
stable virtual address
        +
endpoint selection
        +
load balancing
```

An `InferencePool` provides an abstraction specifically for inference workloads:

```text
InferencePool
      │
      ├── identifies inference Pods
      ├── identifies target ports
      └── associates an Endpoint Picker
```

The Gateway API Inference Extension describes an InferencePool as a specialized backend for inference workloads rather than simply another representation of a Service.

---

# 6. HTTPRoute

The simulated HTTPRoute demonstrates the Gateway API relationship:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: llama-3-8b-route
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
```

The important point is:

```yaml
group: inference.networking.k8s.io
kind: InferencePool
```

rather than:

```yaml
kind: Service
```

The Gateway API Inference Extension documentation uses this same model: an HTTPRoute can reference an InferencePool as its backend, allowing the Gateway implementation to invoke the endpoint-selection extension.

---

# 7. OpenAI-compatible API

The simulated model server exposes:

```text
POST /v1/chat/completions
```

Test it with:

```bash
kubectl port-forward svc/llama-3-8b 8080:8000
```

Then:

```bash
curl -s http://localhost:8080/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "meta-llama/Llama-3.1-8B-Instruct",
    "messages": [
      {
        "role": "user",
        "content": "Hello"
      }
    ]
  }'
```

This is an API-shape test. The simulator is not actually loading or executing Llama 3.1 8B.

---

# 8. What the local simulation does and does not prove

## It DOES demonstrate

- Kubernetes CRD discovery
- `kubectl explain`
- `LLMInferenceService`
- Gateway API
- `HTTPRoute`
- `InferencePool`
- Endpoint Picker association
- inference-pod selection
- OpenAI-compatible API shape
- the architectural relationship between the resources

## It DOES NOT demonstrate

- KServe controller reconciliation
- `LLMInferenceService Ready=True`
- real vLLM inference
- GPU scheduling
- real KV-cache utilisation
- production prefix-cache-aware scheduling
- a working Gateway implementation
- end-to-end Gateway → EPP → model-server traffic

Those require the full KServe/inference-gateway stack.

KServe's full LLMInferenceService installation has substantially more dependencies, including Gateway API, Gateway API Inference Extension, Gateway provider infrastructure and other components. Keeping those out of this local lab is intentional.

---

# 9. Exam takeaways

For CKNE, retain the architecture rather than memorising the exact YAML:

```text
LLMInferenceService
        │
        ▼
Gateway API
        │
     HTTPRoute
        │
        ▼
InferencePool
        │
        ▼
Endpoint Picker
        │
        ▼
Inference Pods
```

The key networking concept is:

> **LLM inference traffic may need inference-aware endpoint selection rather than ordinary round-robin Service balancing.**

Remember the reason:

```text
conversation context
        ↓
KV-cache locality
        ↓
better backend selection
        ↓
less prefix/prefill recomputation
        ↓
better latency / throughput
```

And remember the practical exam technique:

```bash
kubectl explain llminferenceservice.spec
kubectl explain llminferenceservice.spec.router
kubectl explain inferencepool.spec
```

**Inspect the API available in the exam environment before constructing the YAML.**