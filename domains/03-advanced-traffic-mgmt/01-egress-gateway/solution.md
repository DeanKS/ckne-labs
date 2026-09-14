# Solution: Cilium Egress Gateway

## The one thing to know before you write any YAML

Cilium's egress gateway and Cilium ClusterMesh cannot be enabled together on the same datapath. If a task scenario mentions both egress gateways and multi-cluster in the same sentence, that's either two separate clusters/policies, or a trick — check which one is actually being asked for before configuring anything.

## Enable the feature (if not already on)

```bash
helm upgrade cilium cilium/cilium --namespace kube-system --reuse-values \
  --set egressGateway.enabled=true
kubectl -n kube-system rollout restart ds/cilium
```

## Policy

```yaml
apiVersion: cilium.io/v2
kind: CiliumEgressGatewayPolicy
metadata:
  name: egress-external-api
spec:
  selectors:
  - podSelector:
      matchLabels: {}
      namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: ai-workload
  destinationCIDRs:
  - "203.0.113.0/24"
  egressGateway:
    nodeSelector:
      matchLabels:
        egress-node: "true"
    egressIP: "10.168.60.100"
```

Selecting the whole namespace (empty `podSelector.matchLabels` plus a `namespaceSelector`) rather than a specific pod label is deliberate here — the task says "all traffic from pods in ai-workload," not a specific app, so scoping to a pod label would under-match.

## Verify source IP at the destination

From a pod in `ai-workload`:

```bash
kubectl -n ai-workload run egress-test --image=curlimages/curl --rm -it --restart=Never -- \
  curl -s http://ifconfig.me   # or your own listener inside 203.0.113.0/24 that logs source IP
```

Should report `10.168.60.100`. Traffic to any address outside `203.0.113.0/24` from the same pod should still show normal node SNAT — confirm with a second `curl` to something outside the CIDR.

## Status / failure visibility

```bash
kubectl get ciliumegressgatewaypolicy egress-external-api -o yaml
cilium-dbg egress list   # run inside a cilium-agent pod
```

If the labeled gateway node is cordoned or down, Cilium does **not** silently reassign the egress IP to another node by default — that's the point of pinning it, so the vendor's allowlist stays valid. `cilium-dbg egress list` and the policy's own conditions will show the egress path is currently unreachable rather than quietly routing through a different node with a different source IP.

## Common failure modes

- Forgetting `egressGateway.enabled=true` was ever set — the CRD can exist and apply cleanly with the feature flag off, and nothing will happen; there's no admission-time error.
- ClusterMesh already enabled on the same Cilium install — the policy will not take effect, and this is easy to miss since nothing shouts about the conflict.
- Picking a node for `egressGateway.nodeSelector` that doesn't actually have `10.168.60.100` configured as a real address — Cilium expects the IP to already exist on the node's interface (or be within an already-routed CIDR on that node); it does not provision the address for you.
