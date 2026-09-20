# CKNE Domains & Competencies (official, beta)

Source: https://training.linuxfoundation.org/certification/certified-kubernetes-network-engineer-ckne/ (retrieved during a live check — beta status, $99 price, 2-hour proctored performance exam, one free retake, 12-month eligibility window, cert valid 2 years).

## 1. Core Infrastructure and CNI — 15%

- Installing and Configuring CNI Plugins
- Managing IPAM and Pod CIDR Allocation
- Using Linux Tools (`iptables`, `ip`, `tcpdump`) for Packet-level Issues
- Troubleshooting Pod Connectivity (DNS, pod-to-pod)
- Configuring Multi-interface Pods

Covered by: `domains/01-core-infra-cni/` — including a dedicated Cilium CLI install + Helm-value-mapping scenario (03), added after review found this under-tested relative to how heavily real beta feedback emphasizes it.

## 2. Service Networking and DNS — 25%

- Configuring L4 Services
- Understanding kube-proxy and CNI Alternatives
- Customizing CoreDNS for Services
- Troubleshooting Service Network Traffic
- Configuring Pod Endpoint Availability
- Managing Traffic with the Gateway API (Gateway, HTTPRoutes)

Covered by: `domains/02-service-networking-dns/`

## 3. Advanced Traffic Management — 20%

- Optimizing LLM Traffic
- Implementing Routing to Expose Networks
- Configuring Egress Gateways for Cluster Exit Traffic
- Implementing Cross-Cluster Service Discovery and Load Balancing

Covered by: `domains/03-advanced-traffic-mgmt/`

## 4. Network Security and Policy — 25%

- Securing Traffic with Network Policies
- Implementing Node and Pod Level Encryption
- Managing TLS Certificates for Gateway API
- Implementing Pod-level Authentication and Authorization

Covered by: `domains/04-network-security-policy/` — including Istio `PeerAuthentication`/`AuthorizationPolicy` (scenario 04), cert-manager-issued Gateway TLS (scenario 05), and L7 `CiliumNetworkPolicy` (scenario 06), added after real beta-exam feedback flagged all three as exam-relevant. See `docs/exam-strategy.md`.

## 5. Observability — 15%

- Analyzing Network Health Using Metrics
- Troubleshooting End-to-End Network Performance with Tracing
- Auditing Traffic with Logs

Covered by: `domains/05-observability/` — including distributed tracing with Jaeger (scenario 03) and gateway access log reading (scenario 04).

## Gaps not yet covered in this repo (contributions welcome)

- IPAM allocation troubleshooting beyond `host-local` (e.g. `whereabouts`, cluster-wide IP exhaustion scenarios)
- Istio traffic management (`VirtualService`, `DestinationRule`) — current Istio coverage is security-only (PeerAuthentication/AuthorizationPolicy); real beta feedback emphasized security specifically, but traffic-shaping with Istio primitives isn't covered
- SPIFFE/SPIRE outside of a service mesh's own built-in identity (Istio/Cilium handle this internally in the current labs)

See `docs/exam-strategy.md` for a fuller writeup of what a real beta exam sitter reported, and how it shaped what's in this repo versus what's still missing.
