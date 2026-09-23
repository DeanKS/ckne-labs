# CKNE Practice Exam (20 scenario questions)

Format matches the real CKNE: performance-based scenario prompts against a live cluster, not multiple choice. Question count per domain is weighted to the official percentages (15/25/20/25/15 → 3/5/4/5/3 out of 20). Answers and grading notes are in `ANSWERS.md` - attempt each one on a real cluster before checking.

Suggested time: 2 hours total, matching the real exam window.

---

## Domain 1 - Core Infrastructure and CNI (3 questions)

**Q1.** A pod is stuck in `ContainerCreating` with event `failed to find plugin "bridge" in path [/opt/cni/bin]`. Fix it without reinstalling the entire CNI, and explain what the error tells you about where the failure actually is (binary vs. config vs. kubelet).

**Q2.** Two CNI conflist files exist in `/etc/cni/net.d/`: `05-old.conflist` (name `oldnet`, subnet `10.5.0.0/16`) and `10-new.conflist` (name `newnet`, subnet `10.6.0.0/16`). New pods keep getting `10.5.x.x` addresses even though you intended `10.6.0.0/16` to be authoritative. Explain why, and fix it.

**Q3.** A pod needs a second, isolated interface on `172.20.0.0/24` in addition to its normal cluster network, without changing the primary CNI. Name the mechanism you'd use and the two Kubernetes objects required.

---

## Domain 2 - Service Networking and DNS (5 questions)

**Q4.** A `ClusterIP` Service has 3 backend pods; `kubectl get endpoints` lists all 3, but roughly a third of requests fail. What object would you check that `Endpoints` can't tell you, and why?

**Q5.** You need `internal.corp.example` to resolve via an internal resolver at `10.0.0.53`, while everything else - including all cluster Services - keeps working exactly as today. Where do you make this change, and what's the risk of getting the block structure wrong?

**Q6.** Explain, in one or two sentences, the practical difference between kube-proxy's `iptables` mode and `ipvs` mode that would make you choose one over the other at scale.

**Q7.** Using Gateway API (not Ingress), route requests with header `x-beta: true` to one backend and everything else to another, on the same path prefix. What's the one rule-ordering mistake that silently breaks this?

**Q8.** An `HTTPRoute`'s status shows `ResolvedRefs: False`. What are two distinct root causes that produce this exact condition, and how do you tell them apart from the status message alone?

---

## Domain 3 - Advanced Traffic Management (4 questions)

**Q9.** You need all egress from one namespace to one external CIDR to consistently originate from a single, fixed IP, regardless of which node the source pod lands on. Name the Cilium feature and the two things it is documented as being incompatible with.

**Q10.** Two Cilium-managed clusters need a single Service name to load-balance across backends in both clusters. What three steps are required, and why won't `kubectl get endpoints` in either cluster ever show the other cluster's pods?

**Q11.** Why does naive round-robin load balancing hurt performance specifically for LLM inference traffic, and what's the name of the KServe CRD purpose-built to avoid it?

**Q12.** A `CiliumEgressGatewayPolicy` applies cleanly with no errors, but traffic still exits via normal node SNAT instead of the pinned egress IP. Name the most common root cause that produces exactly this symptom.

---

## Domain 4 - Network Security and Policy (5 questions)

**Q13.** After applying a default-deny `NetworkPolicy` (both directions) plus an ingress-only allow rule from `app-a` to `app-b`, `app-a` still can't reach `app-b`. What's missing, and why doesn't an ingress allow rule alone fix it?

**Q14.** What's the one Helm flag change most likely to silently reset unrelated Cilium configuration (kube-proxy replacement, IPAM mode, etc.) when you only meant to enable WireGuard encryption?

**Q15.** Same-node pod-to-pod traffic shows up unencrypted even after WireGuard node encryption is confirmed enabled and working. Is this a bug? Explain.

**Q16.** You need the Gateway to validate an upstream backend's TLS certificate against a private CA before forwarding traffic to it. Which Gateway API object handles this, and what does it attach to - the Gateway, the HTTPRoute, or the Service?

**Q17.** A ServiceAccount only needs to read ConfigMaps in its own namespace. What's wrong with granting this via a `ClusterRole` + `ClusterRoleBinding` even if the verbs listed are otherwise correct?

---

## Domain 5 - Observability (3 questions)

**Q18.** You've set `bandwidthManager.enabled=true` in the Cilium Helm values and the upgrade succeeded with no errors. What single further check confirms the feature is actually active in the eBPF datapath rather than just configured?

**Q19.** Security wants an hour's worth of evidence of exactly which flows were dropped by policy, with source/destination/port. Why is `hubble observe --follow` alone insufficient for this, even though it shows the right data live?

**Q20.** An application's own logs show a connection timing out to a downstream Service. Name the observability layer that can tell you *whether* this is a NetworkPolicy denial versus a genuine backend outage, and why app-level logs alone can't distinguish the two.

---

## Bonus questions (not weighted into the 20 above)

Added after real beta-exam feedback surfaced gaps in the original set - see `docs/exam-strategy.md`. These sit outside the weighted 15/25/20/25/15 count above so the existing answer numbering doesn't shift; treat them as supplementary practice for the four scenarios added afterward.

**B1.** A Service is created with no `selector`. You confirm the Service and its ClusterIP exist, but nothing can reach it. What's missing, and why doesn't Kubernetes create it automatically the way it would for a normal Service?

**B2.** A request into `payments` fails. You need to tell whether it was rejected because it wasn't encrypted at all, or because it was properly authenticated over mTLS but simply not permitted. Name the two Istio objects responsible for each layer, and how the two failure modes look different when you test them.

**B3.** A Gateway's HTTPS listener references a Secret that a `Certificate` object is supposed to keep populated. The `Gateway` looks perfectly healthy. What's the one thing you should check to be sure the certificate isn't quietly failing to renew, and why won't the Gateway itself ever tell you that?

**B4.** You're given a trace in Jaeger showing `frontend → backend → db`, and the `backend` span is the longest single bar in the waterfall. Why might fixing `backend` be the wrong move, and what would you check in the trace before concluding that?
