# Practice Exam — Answers & Grading Notes

## Domain 1

**A1.** The error is specifically about the CNI *binary* being missing from `/opt/cni/bin`, not the conflist config — config parsing already succeeded enough for the kubelet to know it wants the `bridge` plugin. Fix: copy/install the `bridge` binary into `/opt/cni/bin` on the affected node(s) (`docker exec <node> ls /opt/cni/bin` to confirm which are actually missing first — don't assume it's all of them). No config change needed. See `domains/01-core-infra-cni/01-manual-cni-config` for the related conflist mechanics.

**A2.** CNI reads `/etc/cni/net.d/` in lexical filename order and uses only the first valid file — `05-old.conflist` sorts before `10-new.conflist` and wins. Fix: rename/remove the old file, or rename the new one to sort first (e.g. `01-new.conflist`). Renaming alone doesn't retroactively fix already-running pods; only new CNI ADD calls are affected.

**A3.** Multus, as a meta-plugin. Required objects: a `NetworkAttachmentDefinition` describing the second network, and a pod annotation (`k8s.v1.cni.cncf.io/networks`) referencing it. See `domains/01-core-infra-cni/02-multi-interface-pods`.

## Domain 2

**A4.** `EndpointSlices` — specifically their per-address `conditions.ready`/`serving`/`terminating` fields. `Endpoints` is a flat list kept for compatibility and doesn't carry these conditions; kube-proxy and CNI datapaths actually watch EndpointSlices, so a pod can be listed as an "endpoint" while still being excluded from the routable set for readiness reasons that plain `Endpoints` can't express. See `domains/02-service-networking-dns/01-l4-services-and-endpoints`.

**A5.** In the CoreDNS `Corefile`, as a separate server block scoped to `internal.corp.example:53` with its own `forward . 10.0.0.53`. Risk: if you nest it inside the existing `.:53` block instead of as its own top-level zone block, it won't match correctly and can instead interfere with the default `kubernetes` plugin's resolution for cluster Services. See `domains/02-service-networking-dns/02-coredns-customization`.

**A6.** `iptables` mode programs a linear chain of rules per Service/endpoint that's evaluated sequentially — lookup cost grows with Service count. `ipvs` mode uses a hash table for O(1)-ish lookups regardless of Service count, so it scales better on clusters with many Services. (A correct answer can also mention CNI-native/eBPF replacement of kube-proxy entirely as the modern alternative to both.)

**A7.** Putting the header-matched (more specific) rule after the plain path-prefix catch-all rule. Gateway API evaluates `HTTPRoute` rules in written order, first match wins — it does not auto-prioritize by specificity, so the catch-all swallows everything if it comes first. See `domains/02-service-networking-dns/03-gateway-api-httproute`.

**A8.** Two common causes: (1) the referenced `backendRef` Service doesn't exist or has no port matching what the rule specifies; (2) the `HTTPRoute` lives in a different namespace from the `Gateway` and the Gateway's listener `allowedRoutes` doesn't permit it. `kubectl describe httproute` shows a human-readable reason string that distinguishes them — don't guess from the boolean status alone.

## Domain 3

**A9.** Cilium Egress Gateway. Documented as incompatible with: ClusterMesh (on the same datapath), and it also does not automatically fail over the pinned egress IP to a different node if the gateway node goes down (by design — the whole point is a stable, allowlistable IP). See `domains/03-advanced-traffic-mgmt/01-egress-gateway`.

**A10.** Steps: (1) `cilium clustermesh enable` on both clusters, (2) `cilium clustermesh connect` between them, (3) annotate the Service `io.cilium/global-service="true"` in *both* clusters. `kubectl get endpoints` never shows the peer cluster because `Endpoints`/`EndpointSlice` are strictly per-cluster Kubernetes API objects — the merged view only exists in Cilium's own eBPF service map, checked via `cilium service list` or Hubble. See `domains/03-advanced-traffic-mgmt/02-clustermesh-cross-cluster`.

**A11.** Each LLM inference replica holds a KV-cache built from prior turns of a conversation; round-robin routes follow-up requests to a replica without that cached context, forcing expensive prefill recomputation instead of reusing it. The CRD is KServe's `LLMInferenceService` (v0.16+), which provisions a router/scheduler and an `InferencePool` (a Gateway API Inference Extension concept) instead of a plain Service. See `domains/03-advanced-traffic-mgmt/03-llm-inference-routing`.

**A12.** The `egressGateway.enabled=true` Helm flag was never actually set (or was reset by a later `helm upgrade` without `--reuse-values`) — the CRD applies successfully regardless of whether the feature flag is on, since there's no admission-time validation tying policy creation to feature availability.

## Domain 4

**A13.** The mirrored egress-side rule on `app-a` allowing traffic *to* `app-b`. `NetworkPolicy` ingress and egress rules are evaluated independently per source/destination pod — an ingress allow on `app-b` doesn't implicitly open egress on `app-a` once default-deny-egress applies to it. Both sides need their own matching rule. See `domains/04-network-security-policy/01-network-policies`.

**A14.** Running `helm upgrade` without `--reuse-values`. Any flags not explicitly re-specified reset to chart defaults, silently reverting kube-proxy replacement mode, IPAM mode, or other prior customizations. See `domains/04-network-security-policy/02-wireguard-encryption`.

**A15.** Not a bug — expected behavior. WireGuard node encryption protects traffic that actually crosses the node boundary over the physical/virtual network. Two pods on the same node communicate entirely within that node's kernel and never traverse the encrypted tunnel, so there's nothing for WireGuard to encrypt in that path.

**A16.** `BackendTLSPolicy`. It attaches to a **Service** via `targetRefs`, not the `Gateway` or `HTTPRoute` — a common mistake is trying to configure this on the Gateway or Route object where it will simply not apply. See `domains/04-network-security-policy/03-gateway-tls`.

**A17.** A `ClusterRole`+`ClusterRoleBinding` grants the permission across **every** namespace in the cluster, not just the ServiceAccount's own namespace — even with correct, minimal verbs, the scope itself violates least privilege. The fix is a namespaced `Role`+`RoleBinding` instead.

## Domain 5

**A18.** Query the feature-enablement metric directly — e.g. `cilium_feature_adv_connect_and_lb_bandwidth_manager_enabled` via Prometheus/`cilium-dbg`/exposed metrics endpoint — and confirm it returns `1`. A successful Helm upgrade only confirms Cilium *accepted* the setting, not that the eBPF datapath actually engaged it (it can silently no-op on unsupported kernels). See `domains/05-observability/01-hubble-metrics`.

**A19.** `hubble observe --follow` only streams what's currently flowing and Hubble's internal buffer is bounded and rotates — restarting the agent/relay loses history before that point. Durable evidence requires exporting flows (e.g. `hubble.export.static`) to a persistent log, ideally shipped off-node. See `domains/05-observability/02-flow-logs-audit`.

**A20.** Hubble (or equivalent eBPF-based flow observability). Application logs only show the symptom from the client's point of view — a timeout looks the same whether caused by a NetworkPolicy DROP verdict or a genuinely down backend. Hubble flow data carries the actual verdict (`FORWARDED` vs `DROPPED`) and, for Cilium-native policies, which policy produced it — information application logs have no visibility into at all.

---

## Bonus questions

**AB1.** A manually created `EndpointSlice`, labeled `kubernetes.io/service-name: <service-name>` so it's associated with the Service. Kubernetes only auto-generates EndpointSlices when a Service has a `selector` for the EndpointSlice controller to reconcile against — remove the selector and nothing watches for backends on your behalf, by design, since a selector-less Service is meant for exactly this "I'm pointing at something outside normal pod discovery" case. See `domains/02-service-networking-dns/04-headless-service-manual-endpoints`.

**AB2.** `PeerAuthentication` governs mTLS/identity (authentication); `AuthorizationPolicy` governs what an authenticated identity is allowed to do (authorization). A request with no valid mTLS at all fails at the connection level under `STRICT` mode — no HTTP response, the handshake itself is refused. A request that authenticates successfully but isn't permitted gets a clean HTTP 403 from the Envoy sidecar — proof it got past the identity layer and was still denied. The two look different specifically because one fails before HTTP even exists and the other fails with a proper HTTP status. See `domains/04-network-security-policy/04-istio-mtls-authz`.

**AB3.** Check the `Certificate` object directly — `kubectl describe certificate` and its `Ready` condition/events — not the Gateway. The Gateway only reads whatever is currently sitting in the referenced Secret; it has no visibility into cert-manager's issuance or renewal process and will report healthy right up until the stale certificate actually expires and client TLS validation starts failing. See `domains/04-network-security-policy/05-cert-manager-gateway-tls`.

**AB4.** A parent span's duration includes all of its children's durations, so the longest bar isn't necessarily where the actual work happened — if `backend`'s child span calling `db` accounts for most of that time, `db` is the real bottleneck and `backend` is mostly just waiting. Before concluding anything, check the split between the span's self-time and its children's time (or look for a large gap between when the parent starts and its first child begins, which can point to connection/handshake overhead rather than either service's own logic). See `domains/05-observability/03-distributed-tracing-jaeger`.

---

## Rough scoring guide

This isn't an official pass mark (CKNE's real cutoff hasn't been published as of this repo's writing), but as a self-check: if you can answer 16+/20 correctly and unaided, and can additionally *perform* the corresponding `domains/` lab live rather than just state the answer, you're in reasonable shape to attempt the real exam.
