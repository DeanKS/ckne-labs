# Further Study (non-Cilium, non-official resources)

`docs/resource-map.md` is deliberately scoped to official documentation and Cilium's own labs, so it stays a reliable, low-noise reference. This file is the opposite — a running list of third-party material (courses, community labs, tutorials) that's relevant to CKNE prep but isn't official and hasn't necessarily been vetted the way the scenarios in this repo have been. Treat everything here as "worth a look," not "verified against the exam."

## Istio (Domain 4 — complements `04-network-security-policy/04-istio-mtls-authz`)

- **KodeKloud's Istio Service Mesh course** — hands-on labs covering install, traffic management, security, and observability, same browser-based lab format as their CKA/CKS/CKNE-adjacent content.
- **Solo.io's free Istio labs** — shorter, task-focused labs (joining workloads, verifying mTLS, L4/L7 policy, circuit breaking, fault injection). Not CKNE-branded, but the mTLS-verification labs specifically overlap with what we built.
- **[redhat-scholars/istio-tutorial](https://github.com/redhat-scholars/istio-tutorial)** (GitHub) — free, self-hosted, no paywall; walks through a real multi-service app on Istio. Good if you'd rather run something yourself than use a hosted platform.

## General Kubernetes networking / CNI / CoreDNS (Domains 1–2)

- **KodeKloud's "Kubernetes Networking Deep Dive" course** — the strongest non-Cilium match found so far. Explicitly structured around CNI (Calico/Flannel/Weave/Cilium), CoreDNS, kube-proxy, and Network Policies, with instant browser-based labs throughout. Worth noting: there's an active KodeKloud community thread (as of this repo's last update) asking exactly "does this course cover enough for CKNE," with no confirmed answer yet — treat it as a strong general refresher, not a confirmed CKNE match.

## cert-manager + Gateway API (Domain 4 — complements `04-network-security-policy/05-cert-manager-gateway-tls`)

Nothing at genuine interactive-lab quality exists here yet — what's out there is blog-tutorial-grade (cert-manager's own docs page on securing Gateway API resources, a handful of vendor walkthroughs from kgateway/Solo.io/Vultr). Our own scenario plus cert-manager's official docs is currently the best version of this that exists publicly; not worth chasing further unless that changes.

## Noted but not yet verified

A GitHub PR for a `killercoda-labs` repository was found using `ckne/`-prefixed directory names strikingly similar to this repo's own structure (e.g. a `ckne/04-security-and-policy/mtls-without-a-mesh` scenario). This appears to be an independent, unrelated effort by another author — CKNE is a public exam name, so parallel community efforts aren't surprising — rather than anything connected to this repo. At the time it was found, the PR's own description indicated several scenarios were "specs only, no index.json... ready to build," meaning not yet actually built. Worth a bookmark to check back on later, not something to rely on for prep right now.

## How to use this list

Nothing here should be treated as authoritative the way `docs/exam-domains.md` or `docs/resource-map.md` are. If you work through one of these and it turns out to be genuinely high-value (or genuinely wrong) for CKNE prep specifically, that's worth a note back into this file — or, if it's good enough to justify a dedicated scenario, into `domains/` itself, the same way real beta-exam feedback shaped several scenarios already in this repo.
