# Scenario: Cilium ClusterMesh Global Services

**Domain:** Advanced Traffic Management (20%)
**Competencies:** Implementing Cross-Cluster Service Discovery and Load Balancing

## Context

Two clusters, `cluster1` and `cluster2`, both run Cilium as CNI and both have a Service named `catalog-svc` backed by local pods. You need clients in `cluster1` to load-balance across backends in **both** clusters transparently.

## Task

1. Enable ClusterMesh on both clusters and connect them.
2. Mark `catalog-svc` as a Global Service in both clusters.
3. Confirm that a client in `cluster1` calling `catalog-svc.default.svc.cluster.local` gets responses from pods in **either** cluster.

## Success criteria

- `cilium clustermesh status` on both clusters shows the other as connected/ready.
- `catalog-svc` in `cluster1` has endpoints listed from both clusters (check via `cilium service list` or Hubble, not just `kubectl get endpoints`, which is cluster-local by definition).
- Killing all `catalog-svc` backend pods in `cluster1` doesn't cause client-side errors - traffic shifts entirely to `cluster2` backends.

## Official documentation

- Cilium ClusterMesh introduction - https://docs.cilium.io/en/latest/network/clustermesh/intro/
- ClusterMesh setup - https://docs.cilium.io/en/stable/network/clustermesh/setup/
- ClusterMesh load-balancing (Global Services) - https://docs.cilium.io/en/latest/network/clustermesh/load-balancing/
