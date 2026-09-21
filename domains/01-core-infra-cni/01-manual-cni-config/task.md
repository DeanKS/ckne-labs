# Scenario: Manual CNI Bridge + IPAM Configuration

**Domain:** Core Infrastructure and CNI (15%)
**Competencies:** Installing and Configuring CNI Plugins · Managing IPAM and Pod CIDR Allocation

## Context

A 3-node Kind cluster has been provisioned with `disableDefaultCNI: true`. Nodes are `NotReady` and a test pod is stuck in `ContainerCreating`.

## Task

On every node, configure a CNI 1.0.0 network named `dbnet` that:

1. Uses the `bridge` plugin, attaching to a bridge called `cni0`.
2. Allocates pod IPs from `10.1.0.0/16` via the `host-local` IPAM type, with gateway `10.1.0.1`.
3. Chains a `tuning` plugin that sets the sysctl `net.core.somaxconn` to `500` on the resulting veth.

`setup.sh` installs the `bridge` and `tuning` CNI plugin binaries onto every node for you — Kind's node image only ships a minimal default set (`host-local`, `loopback`, `portmap`, `ptp`), not the full `containernetworking/plugins` bundle, so these two specifically are not present until `setup.sh` puts them there. Do not restart the kubelet or container runtime as part of your fix — you only need to drop the correct conflist once the binaries exist.

## Success criteria

- `cni-test-pod` reaches `Running`.
- Its IP is inside `10.1.0.0/16`.
- `cni0` exists on whichever node ends up running `cni-test-pod` (the `bridge` plugin only creates it lazily, on first use — with a single test pod, don't expect to see it on all three nodes even with a correct conflist on every node).
- `net.core.somaxconn` is set to `500` inside the pod's network namespace.

## Official documentation

- Network plugins (CNI) concept — https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/
- CNI Specification (ADD/DEL/CHECK, conflist format) — https://github.com/containernetworking/cni/blob/main/SPEC.md
- Cluster networking model — https://kubernetes.io/docs/concepts/cluster-administration/networking/
