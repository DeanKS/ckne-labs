# Scenario: Diagnosing Latency with Distributed Tracing

**Domain:** Observability (15%)
**Competencies:** Troubleshooting End-to-End Network Performance with Tracing

## Context

This competency has no other coverage in this repo - `01-hubble-metrics` and `02-flow-logs-audit` cover metrics and logs, but tracing is its own named skill on the official blueprint, and real-world CKNE beta feedback (`docs/exam-strategy.md`) says a pre-installed Jaeger UI, not raw PromQL, is what you're expected to read under exam conditions.

A mesh (Istio or Cilium with tracing enabled) routes `frontend` → `backend` → `db`. Users report the request path is slow, but no single service reports errors - this is a latency hunt, not a failure hunt.

## Task

1. Ensure trace context propagation and a tracing backend (Jaeger) are in place across all three services.
2. Generate a request through the full path and locate its trace in Jaeger.
3. From the trace's span breakdown alone - not logs, not metrics - identify which hop contributes the most latency.

## Success criteria

- A single trace ID is visible spanning all three services (proof context propagation isn't broken anywhere in the chain).
- You can name the specific span (service + operation) responsible for the majority of the total request duration.
- You can distinguish "this span is slow because it's doing real work" from "this span is slow because it's waiting on a child span" - i.e., read the waterfall, not just the biggest number.
