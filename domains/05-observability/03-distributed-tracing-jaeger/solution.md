# Solution: Reading a Distributed Trace for Latency

## Why this is tested separately from metrics

Metrics (Domain 5, scenario 1) tell you *that* something is slow in aggregate - a p99 latency graph going up. They don't tell you *where in a single request's path* the time went, because a metric is already an aggregation across many requests and hops. A trace is the opposite: one request's exact path through every service, broken into spans with start/end timestamps, which is the only data structure that can actually answer "which specific hop, for this specific slow request, ate the time."

## Generating and finding the trace

```bash
kubectl -n mesh-lab exec deploy/frontend -c istio-proxy -- \
  curl -s -o /dev/null -w "trace made\n" http://backend.mesh-lab.svc.cluster.local
```

Open the Jaeger UI (`http://localhost:16686` if you port-forwarded as in `setup.sh`), search by service `frontend`, and open the most recent trace. You'll see a waterfall: one root span for the inbound request, with child spans nested underneath for each downstream call.

## Reading the waterfall correctly

The critical skill: a parent span's duration *includes* all of its children's durations. A `backend` span that's 400ms long isn't necessarily 400ms of `backend`'s own work - if its child span calling `db` is 380ms of that, then `backend` itself only did about 20ms of real work, and `db` is where the actual problem lives. Looking only at "which span has the biggest total duration number" without checking whether that duration is mostly self-time or mostly child-time is the single most common way to misdiagnose this kind of task and fix the wrong service.

Most Jaeger UI views show a "self time" or let you visually see gaps between when a parent span starts waiting on a child and when the child actually responds - a large gap between a parent span's start and its first child span starting can also point at time spent in DNS resolution, TLS handshake, or connection setup rather than in application logic at all.

## Common failure modes

- Fixing the service with the visually longest bar in the waterfall without checking whether that time is self-time or inherited from a child - easy to do quickly under exam time pressure, and exactly why this competency exists as a distinct skill from just glancing at a metric dashboard.
- Missing that a trace doesn't span all three services at all (a broken span in the middle, or a service not instrumented for tracing) - that itself is a valid finding: it tells you context propagation is broken somewhere, not that latency is the problem, and the fix is different (check that the middle service is actually propagating trace headers, e.g. `b3` or `traceparent`, rather than swallowing them).
- Assuming Jaeger data alone will show *why* a span is slow (e.g. lock contention, GC pause, slow query) - tracing tells you *where*, and you typically pair it with that service's logs/metrics to find *why*; don't spend exam time trying to force one tool to answer a question it isn't built to answer.
