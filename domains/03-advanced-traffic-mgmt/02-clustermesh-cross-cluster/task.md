# Scenario: Cilium ClusterMesh Global Services

**WARNING:** This lab is very much a W.I.P. and is not currently stable to run as it creates two clusters which can be highly unstable and taxing on system resources - run at your own risk!!!

**Domain:** Advanced Traffic Management (20%)
**Competencies:** Implementing Cross-Cluster Service Discovery and Load Balancing

## Context

This lab creates two dedicated Kind clusters and configures Cilium ClusterMesh between them.
Two clusters, `cluster1` and `cluster2`, both run Cilium as CNI and both have a Service named `catalog-svc` backed by local pods. You need clients in `cluster1` to load-balance across backends in **both** clusters transparently.

## Environment

The lab has already created two independent Kind clusters:

| Cluster | Kubernetes context | Cilium cluster name | Cilium cluster ID |
|---|---|---|---:|
| Cluster 1 | `kind-ckne-mesh-1` | `cluster1` | `1` |
| Cluster 2 | `kind-ckne-mesh-2` | `cluster2` | `2` |

Both clusters already have Cilium installed and healthy.

The following workload exists in both clusters:

- Namespace: `mesh-lab`
- Deployment: `catalog`
- Service: `catalog`
- Port: `80`

The `catalog` workload in each cluster returns a response identifying
the cluster in which it is running.

## Task

1. Enable ClusterMesh on both clusters and connect them.
2. Mark `catalog-svc` as a Global Service in both clusters.
3. Verify that both clusters report the other cluster as connected.
4. Verify that the Global Service has endpoints in both clusters.
5. Confirm that a client in `cluster1` calling `catalog-svc.default.svc.cluster.local` gets responses from pods in **either** cluster.

The following context names are available:

```text
kind-ckne-mesh-1
kind-ckne-mesh-2```

## Success criteria

- `cilium clustermesh status` on both clusters shows the other as connected/ready.
- `catalog-svc` in `cluster1` has endpoints listed from both clusters (check via `cilium service list` or Hubble, not just `kubectl get endpoints`, which is cluster-local by definition).
- Killing all `catalog-svc` backend pods in `cluster1` doesn't cause client-side errors - traffic shifts entirely to `cluster2` backends.

## Official documentation

- Cilium ClusterMesh introduction - https://docs.cilium.io/en/latest/network/clustermesh/intro/
- ClusterMesh setup - https://docs.cilium.io/en/stable/network/clustermesh/setup/
- ClusterMesh load-balancing (Global Services) - https://docs.cilium.io/en/latest/network/clustermesh/load-balancing/
