# Solution: Multi-Interface Pods with Multus

## Why Multus and not a second primary CNI

Only one CNI plugin can own the pod's primary interface and IPAM lifecycle at a time - that's the contract the kubelet relies on. Multus solves "I need a second network" by acting as a meta-plugin: it stays the one thing the kubelet calls, delegates the primary interface to your real CNI (e.g. Cilium/Calico) exactly as before, and then calls out to additional CNI plugins for every extra interface a pod asks for via annotation. That's why it can be installed without touching your existing CNI config at all - the primary network path is untouched.

## Steps

1. Install Multus (thick plugin, DaemonSet-based):

```bash
kubectl apply -f https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/master/deployments/multus-daemonset-thick.yml
kubectl -n kube-system rollout status daemonset/kube-multus-ds
```

2. Define the secondary network as a `NetworkAttachmentDefinition`:

```yaml
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: storage-net
spec:
  config: '{
    "cniVersion": "1.0.0",
    "type": "bridge",
    "bridge": "br1",
    "ipam": {
      "type": "host-local",
      "subnet": "192.168.100.0/24"
    }
  }'
```

3. Reference it on the pod:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: dual-homed-pod
  annotations:
    k8s.v1.cni.cncf.io/networks: storage-net
spec:
  containers:
  - name: app
    image: nginx
```

## Verification detail worth knowing for the exam

`kubectl exec dual-homed-pod -- ip addr show net1` should show the `192.168.100.0/24` address. The primary CNI still owns `eth0` and the default route - Multus does not touch routing for interfaces it didn't create, so `net1` is reachable but not "the" default route. If a task expects traffic to actually flow out `net1`, you need custom routing (not covered here) - don't assume Multus alone routes for you.

## Common failure modes

- Forgetting to `rollout status` the Multus daemonset before creating the pod - the CNI binary/config may not be dropped on every node yet.
- `NetworkAttachmentDefinition` created in the wrong namespace - it must be in the same namespace as the pod referencing it (or referenced with `<namespace>/<name>` in the annotation).
- Typo'ing the annotation key (`k8s.v1.cni.cncf.io/networks`, not `k8s.v1.cni.cncf.io/network`) - Multus silently ignores annotations it doesn't recognize, and the pod comes up with only `eth0`.
- `cniVersion: 1.1.0` on the delegated config can trigger a runtime `STATUS`-command path some plugin builds don't fully implement - see the fuller writeup in `domains/01-core-infra-cni/01-manual-cni-config/solution.md`, which is where this was actually found on a live cluster. `1.0.0` here avoids it the same way.
