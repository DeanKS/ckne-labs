# Scenario: LLM-Aware Inference Traffic Routing

**Domain:** Advanced Traffic Management (20%)  
**Competencies:** Optimizing LLM Traffic

## Why this scenario looks different from the others

This is the newest competency on the CKNE curriculum and the tooling here (`LLMInferenceService`, `InferencePool`, Endpoint Picker/EPP, and the Gateway API Inference Extension) is still evolving upstream.

This lab therefore deliberately separates:

- **The real Kubernetes APIs** you need to understand for the exam.
- **A lightweight local simulation** of the inference data plane.

You are **not** expected to install GPUs, vLLM, Envoy Gateway, or the KServe controller.

The local lab installs the relevant CRDs and provides lightweight simulated inference-server and Endpoint Picker components. This lets you practise the Kubernetes networking configuration without requiring a GPU-backed LLM stack.

A real exam task is more likely to give you an already-installed inference control plane and ask you to configure or troubleshoot it.

---

## Context

Standard round-robin load balancing across LLM inference replicas is a poor fit for conversational workloads.

Each inference replica may have a different portion of the KV-cache built up from previous requests. If a follow-up request is sent to a different replica, that replica may have to recompute the shared prompt prefix instead of reusing cached context.

LLM-aware inference routing therefore considers inference-specific signals such as:

- KV-cache locality
- queue depth
- active requests
- model/adaptor availability
- other model-server metrics

The Endpoint Picker (EPP) is responsible for helping the inference gateway select an appropriate backend rather than simply using ordinary Service load balancing.

---

# Task

You have a lightweight inference-routing environment containing:

- Gateway API CRDs
- Gateway API Inference Extension CRDs
- KServe `LLMInferenceService` CRD
- a simulated three-replica model server
- a lightweight Endpoint Picker
- a pre-created `InferencePool`

Complete the following tasks.

## 1. Inspect the installed APIs first

Before writing any YAML, determine which API versions and fields are actually installed.

Run:

```bash
kubectl api-resources | grep -Ei 'llminference|inferencepool|gateway|httproute'
```

Then inspect the LLMInferenceService schema:

```bash
kubectl explain llminferenceservice.spec
kubectl explain llminferenceservice.spec.router
kubectl explain llminferenceservice.spec.router.scheduler
```

Also inspect the installed InferencePool:

```bash
kubectl explain inferencepool.spec
kubectl explain inferencepool.spec.endpointPickerRef
```

Use the installed schema and the official documentation as your source of truth rather than relying on memorised YAML.

> **Important:** these APIs are evolving. The exact API version or field names in a future CKNE exam environment may differ from this lab.

---

## 2. Create an LLMInferenceService

Create an `LLMInferenceService` named:

```text
llama-3-8b
```

It should:

- use the Llama 3.1 8B Instruct model identifier
- specify three replicas
- configure the Gateway API route
- configure the scheduler
- reference the existing simulated `InferencePool`

Do **not** install or deploy another model server.

Your service should conceptually look like:

```text
LLMInferenceService
        │
        ├── Gateway API route
        │
        └── Scheduler
              │
              ▼
        InferencePool
              │
              ├── model pod 1
              ├── model pod 2
              └── model pod 3
```

---

## 3. Understand the routing decision

Explain why this architecture is preferable to:

```text
Client
  │
  ▼
Kubernetes Service
  │
  ├── Pod 1
  ├── Pod 2
  └── Pod 3
```

Specifically explain:

1. Why round-robin can be inefficient for conversational LLM traffic.
2. What the KV-cache represents at a high level.
3. What the Endpoint Picker does.
4. Why the `InferencePool` is different from an ordinary Kubernetes Service.

---

## 4. Inspect the routing resources

After creating the `LLMInferenceService`, inspect:

```bash
kubectl get llminferenceservice
kubectl get inferencepool
kubectl get httproute
kubectl get gateway
kubectl get pods
```

Then inspect the pool:

```bash
kubectl get inferencepool llama-3-8b-pool -o yaml
```

Confirm that it selects the simulated model-server Pods:

```bash
kubectl get pods -l app=llama-3-8b
```

Confirm that the Endpoint Picker is running:

```bash
kubectl get deployment llama-3-8b-epp
kubectl get pods -l app=llama-3-8b-epp
```

---

## 5. Verify the OpenAI-compatible endpoint

The local simulation does not include a Gateway implementation, so the HTTPRoute is used to practise the **configuration model**, not to provide an externally reachable Gateway.

Instead, access the simulated model server directly:

```bash
kubectl port-forward svc/llama-3-8b 8080:8000
```

In another terminal:

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

The simulator does not perform real LLM inference. The important point is that the endpoint follows the OpenAI-compatible `/v1/chat/completions` interface.

---

## Local simulation versus real KServe

This lab intentionally does **not** claim that the local `LLMInferenceService` becomes `Ready`.

A real KServe installation has a controller which watches the `LLMInferenceService` and creates/manages the associated workload, Gateway/HTTPRoute, InferencePool, InferenceModel and Endpoint Picker resources.

This lab installs the CRDs but not that controller.

Therefore:

### Full KServe environment

```text
LLMInferenceService
       │
       ▼
KServe controller
       │
       ├── Deployment
       ├── Service
       ├── Gateway
       ├── HTTPRoute
       ├── InferencePool
       ├── InferenceModel
       └── EPP
```

### This local CKNE simulation

```text
LLMInferenceService ────────┐
                            │
Gateway/HTTPRoute ──────────┤
                            ├── real Kubernetes APIs
InferencePool ──────────────┤
                            │
Simulated model servers ────┤
                            │
Lightweight EPP ─────────────┘
```

The objective is to practise the **API shape, resource relationships and networking concepts**, not reproduce a production LLM serving platform.

---

## Success criteria

- `LLMInferenceService` named `llama-3-8b` exists.
- The installed `LLMInferenceService` schema accepts your manifest.
- The service contains the expected model and router configuration.
- `InferencePool` `llama-3-8b-pool` exists.
- The pool selects the three simulated inference Pods.
- The Endpoint Picker is running.
- An `HTTPRoute` exists and references the `InferencePool`.
- The simulated inference service responds to `/v1/chat/completions`.
- You can explain why inference-aware routing can prefer a backend with useful KV-cache state instead of using ordinary round-robin balancing.

### What this does NOT prove

This local scenario does **not** prove that a real KServe controller has reconciled the `LLMInferenceService` or that production KV-cache-aware routing is occurring.

Those behaviours require a real KServe/inference-gateway implementation.

---

## Official documentation

- KServe LLMInferenceService:
  https://kserve.github.io/website/docs/model-serving/generative-inference/llmisvc/llmisvc-overview
- KServe LLMInferenceService configuration:
  https://kserve.github.io/website/docs/model-serving/generative-inference/llmisvc/llmisvc-configuration
- Gateway API Inference Extension:
  https://gateway-api-inference-extension.sigs.k8s.io/
- InferencePool:
  https://gateway-api-inference-extension.sigs.k8s.io/api-types/inferencepool/
- Gateway API:
  https://gateway-api.sigs.k8s.io/