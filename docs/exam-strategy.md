# Exam Strategy (from real beta-exam feedback)

Everything below is distilled from [Jan-Otto Kröpke's account of sitting the CKNE beta](https://jkroepke.de/2026/09/preparing-for-ckne-what-i-learned-from-the-beta-exam/) on 2026-09-17 — the only known published first-hand account at time of writing. Treat it as one data point from one beta sitting, not a guaranteed description of the GA exam, but it's the closest thing to ground truth available right now and it changed how several labs in this repo are structured.

## Breadth beats depth

The exam moves across Cilium, Istio, Gateway API, plain Kubernetes networking, and observability inside a 2-hour window — it rewards being comfortable across all of it rather than being deep on one product. If you only prepared Cilium (a natural bias, since it's the most "networking-native" CNI), you're likely under-prepared for the Istio and cert-manager portions.

## Don't memorize YAML, CRDs, or PromQL

Documentation and context were available in the beta environment — the skill being tested is finding the right reference fast and adapting it, not recalling exact field names from memory. This repo's `solution.md` files intentionally explain *why* a shape is correct rather than presenting it as something to memorize verbatim, for the same reason.

## Low-level Linux tools were less central than expected

The official blueprint still lists `iptables`/`ip`/`tcpdump` under Core Infrastructure and CNI, and this repo's Domain 1 labs use them because that's what the published competency says — but in the actual beta sitting, troubleshooting leaned much more on pre-installed dashboards (Prometheus, Jaeger) than raw packet inspection. Don't skip Domain 1's Linux-tool practice, but don't over-invest in it at the expense of Istio/Gateway API/observability either.

## Istio matters more than this repo originally assumed

`PeerAuthentication` (authentication — mTLS identity) and `AuthorizationPolicy` (authorization — what an authenticated identity can do) came up as a distinct, meaningfully-weighted area. See `domains/04-network-security-policy/04-istio-mtls-authz`.

## cert-manager, not just raw Secrets, for Gateway TLS

Knowing how a `Certificate` ends up as a Secret a `Gateway` listener references — including what happens when issuance or renewal fails — is treated as part of the TLS competency, not just the mechanics of `certificateRefs`. See `domains/04-network-security-policy/05-cert-manager-gateway-tls`.

## Tracing is a real, separate skill

"Troubleshooting End-to-End Network Performance with Tracing" is its own named competency on the official blueprint, distinct from metrics and logs. This repo had no tracing content until this feedback surfaced that gap — see `domains/05-observability/03-distributed-tracing-jaeger`.

## Format and pacing notes

- Textual answers can be typed directly into the browser-based exam interface in some tasks, rather than always requiring a file written to disk under `/opt` (the CKA/CKS convention) — don't assume every task needs a file artifact.
- Validate and move on rather than perfecting one task — if something is taking too long, flag it mentally and come back later. Every `verify.sh` in this repo exists so you build that "solve, check, move on" habit against a script rather than eyeballing it.
- There is currently no CKNE-specific exam simulator (unlike Killer Shell for CKA/CKS/CKAD) — this repo, imperfect as it is, is filling part of that gap deliberately.
