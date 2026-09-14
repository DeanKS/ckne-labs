# Resource Map

Every link from your research table, mapped to the domain and scenario it's most relevant to. `utm_source` tracking params stripped.

## Domain 1 — Core Infrastructure and CNI

- CNI plugin concepts — https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/
- Kubernetes cluster networking model — https://kubernetes.io/docs/concepts/cluster-administration/networking/
- CNI Specification (ADD/DEL/CHECK, conflist format) — https://github.com/containernetworking/cni/blob/main/SPEC.md
- Multus quickstart (multi-interface pods) — https://github.com/k8snetworkplumbingwg/multus-cni/blob/master/docs/quickstart.md
- Multus configuration reference — https://github.com/k8snetworkplumbingwg/multus-cni/blob/master/docs/configuration.md
- Linux kernel networking docs (iptables/ip fundamentals) — https://kernel.org/doc/html/latest/networking/index.html
- DNS debugging & resolution — https://kubernetes.io/docs/tasks/administer-cluster/dns-debugging-resolution/

→ `domains/01-core-infra-cni/01-manual-cni-config`, `domains/01-core-infra-cni/02-multi-interface-pods`

## Domain 2 — Service Networking and DNS

- Services concept — https://kubernetes.io/docs/concepts/services-networking/service/
- Services-networking overview — https://kubernetes.io/docs/concepts/services-networking/
- Virtual IPs and Service proxies (kube-proxy modes, IPVS/iptables) — https://kubernetes.io/docs/reference/networking/virtual-ips/
- Custom nameservers / CoreDNS — https://kubernetes.io/docs/tasks/administer-cluster/dns-custom-nameservers/
- EndpointSlices (pod endpoint availability) — https://kubernetes.io/docs/concepts/services-networking/endpoint-slices/
- Gateway API concept — https://kubernetes.io/docs/concepts/services-networking/gateway/
- HTTPRoute reference — https://gateway-api.sigs.k8s.io/reference/api-types/httproute/
- Ingress (for contrast with Gateway API) — https://kubernetes.io/docs/concepts/services-networking/ingress/

→ `domains/02-service-networking-dns/01-l4-services-and-endpoints`, `.../02-coredns-customization`, `.../03-gateway-api-httproute`

## Domain 3 — Advanced Traffic Management

- Cilium egress gateway — https://docs.cilium.io/en/latest/network/egress-gateway/
- Cilium ClusterMesh intro — https://docs.cilium.io/en/latest/network/clustermesh/intro/
- ClusterMesh setup — https://docs.cilium.io/en/stable/network/clustermesh/setup/
- ClusterMesh load-balancing (Global Services) — https://docs.cilium.io/en/latest/network/clustermesh/load-balancing/
- Cilium overview — https://docs.cilium.io/en/stable/overview/intro/
- Gateway API concept (traffic exposure) — https://kubernetes.io/docs/concepts/services-networking/gateway/
- Envoy AI Gateway / LLM traffic filters — the `ai_protocol_manager_filter` and kgateway links you supplied did not resolve to a documented Envoy filter at time of writing. The real building blocks for the LLM-traffic competency are **KServe's `LLMInferenceService`** (v0.16+) and **`llm-d`**, which implement the **Gateway API Inference Extension**'s `InferencePool`. Use those instead of the two dead links: https://kserve.github.io/website/docs/model-serving/generative-inference/llmisvc/llmisvc-overview and https://gateway-api-inference-extension.sigs.k8s.io/

→ `domains/03-advanced-traffic-mgmt/01-egress-gateway`, `.../02-clustermesh-cross-cluster`, `.../03-llm-inference-routing`

## Domain 4 — Network Security and Policy

- NetworkPolicy concept — https://kubernetes.io/docs/concepts/services-networking/network-policies/
- Cilium WireGuard node encryption — https://docs.cilium.io/en/stable/security/network/encryption-wireguard/
- Linux kernel networking (WireGuard/crypto context) — https://kernel.org/doc/html/latest/networking/index.html
- Gateway API TLS guide — https://gateway-api.sigs.k8s.io/guides/user-guides/tls/
- BackendTLSPolicy reference — https://gateway-api.sigs.k8s.io/reference/api-types/policy/backendtlspolicy/
- Configure a Pod's ServiceAccount — https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/
- RBAC reference — https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- Cilium mutual authentication (pod-to-pod mTLS) — https://docs.cilium.io/en/stable/network/servicemesh/mutual-authentication/mutual-authentication/

→ `domains/04-network-security-policy/01-network-policies`, `.../02-wireguard-encryption`, `.../03-gateway-tls`

## Domain 5 — Observability

- Resource usage monitoring — https://kubernetes.io/docs/tasks/debug/debug-cluster/resource-usage-monitoring/
- Cilium/Hubble metrics — https://docs.cilium.io/en/stable/observability/metrics/

→ `domains/05-observability/01-hubble-metrics`, `.../02-flow-logs-audit`
