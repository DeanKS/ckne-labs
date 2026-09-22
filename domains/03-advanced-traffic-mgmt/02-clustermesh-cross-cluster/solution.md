# Solution: Cilium ClusterMesh Global Services

## Prerequisites that are easy to skip

Every cluster in a mesh needs a **unique** `cluster-id` (1-255) and `cluster-name`, set at Cilium install time via Helm (`--set cluster.id=1 --set cluster.name=cluster1`). If both clusters were installed with the default `cluster.id=0`, ClusterMesh will refuse to connect them - this is the single most common reason a `clustermesh connect` hangs or errors.

## Steps

```bash
# On cluster1 and cluster2 individually, confirm distinct cluster IDs are already set
cilium config view --context cluster1 | grep cluster-id
cilium config view --context cluster2 | grep cluster-id

# Enable ClusterMesh's API server on both
cilium clustermesh enable --context cluster1
cilium clustermesh enable --context cluster2

# Connect them (bidirectional trust is established by this one command)
cilium clustermesh connect --context cluster1 --destination-context cluster2

# Confirm
cilium clustermesh status --context cluster1
cilium clustermesh status --context cluster2
```

## Mark the Service as Global

```bash
kubectl --context cluster1 annotate service catalog-svc io.cilium/global-service="true"
kubectl --context cluster2 annotate service catalog-svc io.cilium/global-service="true"
```

Both sides need the annotation - a Global Service is an agreement between clusters, not a one-sided export.

## Why `kubectl get endpoints` won't show the other cluster

`Endpoints`/`EndpointSlice` objects are strictly cluster-local Kubernetes API resources - cluster2's backends were never reconciled into cluster1's API server and never will be; that's not how ClusterMesh works. Cilium's own eBPF service map is what actually carries the merged backend list. Check it with:

```bash
cilium service list --context cluster1 | grep catalog-svc
# or, for a live view of which cluster a request actually landed in:
hubble observe --to-namespace default -f
```

## Verify failover

```bash
kubectl --context cluster1 scale deployment catalog -0 --replicas=0
# repeatedly curl catalog-svc from a client pod in cluster1 - should keep succeeding,
# now entirely served by cluster2 backends
```

## Common failure modes

- Same `cluster.id` on both clusters - silent connection failure, or worse, ID collisions in the eBPF maps.
- Annotating the Service in only one cluster - global load-balancing is asymmetric in that case; traffic flows one direction but not the other.
- Trying to run ClusterMesh and the egress gateway feature (scenario 01 in this domain) on the same Cilium install - they are documented as mutually exclusive on the same datapath.
