# Scenario: LLM-Aware Inference Traffic Routing

**Domain:** Advanced Traffic Management (20%)
**Competencies:** Optimizing LLM Traffic

## Why this scenario looks different from the others

This is the newest competency on the CKNE curriculum and the tooling here (KServe's `LLMInferenceService`, `llm-d`, the Gateway API Inference Extension) is genuinely still evolving upstream — unlike CNI or NetworkPolicy, there isn't a decade of stable convention to lean on. Treat this scenario as "understand the shape of the architecture and the concepts you'll be tested on," not "memorize this exact YAML." A real exam task will likely give you a pre-installed control plane and ask you to configure or troubleshoot it, not install the whole stack from scratch.

## Context

Standard round-robin load balancing across LLM inference replicas is a bad fit: each replica holds a different portion of the KV-cache built up from prior requests in a conversation, so a naive round-robin router keeps sending follow-up requests to the "wrong" replica, forcing an expensive prefill recomputation instead of reusing cached context. This is why LLM inference routing exists as its own competency separate from ordinary L4/L7 Service routing.

## Task

Given a cluster with KServe (v0.16+) and the Gateway API Inference Extension already installed:

1. Deploy an `LLMInferenceService` for a model, backed by a router + `InferencePool` rather than a plain Kubernetes Service.
2. **Before writing any YAML, check the currently-installed KServe/Gateway API Inference Extension CRD versions on the cluster** (`kubectl explain llminferenceservice.spec`, or the CRD's own docs) and use that as your source of truth over anything memorized — this domain's APIs move fast enough that a remembered field name from even a few months ago can be wrong. This is deliberately part of the task, not just good practice: real beta-exam feedback (`docs/exam-strategy.md`) specifically says this domain rewards fast documentation lookup over memorization.
3. Explain (and demonstrate you understand) why the router picks a specific pod for a given request instead of load-balancing evenly.
4. Confirm the deployment exposes an OpenAI-compatible endpoint (`/v1/chat/completions`).

## Success criteria

- `kubectl get llminferenceservice` shows your service `Ready`.
- An `InferencePool` and its Endpoint Picker (scheduler) exist and are healthy.
- Repeated requests carrying the same conversation context are observably routed with cache locality in mind (same backend where possible), rather than round-robin.

## Official documentation

- KServe LLMInferenceService overview — https://kserve.github.io/website/docs/model-serving/generative-inference/llmisvc/llmisvc-overview
- Gateway API Inference Extension — https://gateway-api-inference-extension.sigs.k8s.io/
- Gateway API concept — https://kubernetes.io/docs/concepts/services-networking/gateway/
