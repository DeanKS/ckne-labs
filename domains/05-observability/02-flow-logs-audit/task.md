# Scenario: Auditing Denied Traffic with Hubble Flow Logs

**Domain:** Observability (15%)
**Competencies:** Auditing Traffic with Logs · Troubleshooting End-to-End Network Performance

## Context

Security asked for evidence of exactly which connections are being blocked by the `NetworkPolicy` set from Domain 4, scenario 1 (`secure-app` namespace), over the last hour — not just "policy exists," but a log of actual denied flows: source, destination, port, and verdict.

## Task

1. Enable Hubble flow export to a persistent, queryable log (not just `hubble observe` live-tailing, which loses history on restart).
2. Produce a filtered view showing only `DROPPED` verdicts in `secure-app`.
3. Identify, from the logs alone, which specific pod-to-pod pair is being denied by which policy.
