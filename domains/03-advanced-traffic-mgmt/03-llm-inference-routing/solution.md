# Solution / Concept Walkthrough: LLM-Aware Traffic Routing

## The architecture, in order

1. **`LLMInferenceService`** (KServe CRD, GA-ish since KServe v0.16) is the top-level object you create. Unlike the older `InferenceService` (built for classic ML predictors), it's purpose-built for generative workloads: streaming responses, multi-turn context, OpenAI-compatible endpoints.
2. Under the hood, KServe provisions an **`InferencePool`** — a group of backend replicas (typically vLLM pods) that is explicitly *not* just a Service with round-robin/random balancing. It's the Gateway API Inference Extension's abstraction for "a pool of interchangeable-but-not-identical-state inference workers."
3. In front of the pool sits a **router + scheduler** (in `llm-d`, the "Endpoint Picker"/EPP). The scheduler picks a backend per-request using signals like KV-cache locality (has this replica already processed a prefix of this conversation?) and current load — not round-robin.
4. A **Gateway** (Gateway API `Gateway`/`HTTPRoute`, often fronted by Envoy AI Gateway for OpenAI-compatible edge features like token-based rate limiting) exposes the whole thing externally.

## Minimal LLMInferenceService shape

```yaml
apiVersion: serving.kserve.io/v1alpha1   # verify against your installed KServe version — this API is still moving
kind: LLMInferenceService
metadata:
  name: llm-vllm
spec:
  model:
    uri: "hf://meta-llama/Llama-3.1-8B-Instruct"
  router:
    route: {}      # empty route = KServe wires up sensible Gateway API defaults for you
    scheduler: {}  # empty scheduler = KServe provisions the llm-d Endpoint Picker
```

Do not memorize the exact field names here for the exam — the important thing to be able to say out loud is: *this CRD creates a router, a scheduler, and an InferencePool, and none of those exist for a plain `InferenceService`.*

## Why KV-cache locality beats round-robin

When a client sends turn 2 of a conversation, the prompt is turn 1 + turn 2 concatenated. If turn 2 lands on the same replica that processed turn 1, that replica's KV-cache already holds the attention state for the shared prefix and only needs to compute the new tokens — a fraction of the work. If round-robin sends it to a different replica, that replica has to recompute the entire prefix from scratch. This is purely a routing decision, not a model change, which is why it's tested as a *networking* competency rather than an ML one.

## Confirming it's working (conceptually)

```bash
kubectl get llminferenceservice llm-vllm
kubectl get inferencepool -l serving.kserve.io/inferenceservice=llm-vllm
kubectl get pods -l serving.kserve.io/inferenceservice=llm-vllm

curl -s http://<gateway-address>/v1/chat/completions \
  -d '{"model":"llm-vllm","messages":[{"role":"user","content":"hello"}]}'
```

For cache-locality behavior specifically, you'd trace which backend pod actually served each turn of a multi-turn conversation (via access logs or Hubble flow data) and confirm the same replica is preferred across turns of one conversation, and that this preference is broken deliberately (e.g. replica under heavy load) rather than randomly.

## What to actually retain for the exam

- The name of the CRD (`LLMInferenceService`) and that it's KServe-specific, introduced for generative workloads specifically (not the older `InferenceService`).
- That the abstraction it creates is an `InferencePool`, and that pool is a Gateway API Inference Extension concept, not a bespoke KServe one.
- The *reason* naive load balancing is wrong here (KV-cache locality / prefill cost), since this is the kind of "why" question performance-based exams like to probe with a task that looks broken until you understand the underlying mechanism.
