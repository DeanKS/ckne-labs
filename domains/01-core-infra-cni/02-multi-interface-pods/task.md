# Scenario: Multi-Interface Pods with Multus

**Domain:** Core Infrastructure and CNI (15%)
**Competencies:** Configuring Multi-interface Pods · Installing and Configuring CNI Plugins

## Context

The cluster is already running with a primary CNI installed (default pod network). A workload team needs one pod to also join a separate, isolated "storage" network on `192.168.100.0/24` in addition to its normal pod network - without touching the primary CNI config.

## Task

1. Install Multus as a meta-plugin so pods can request additional interfaces.
2. Define a `NetworkAttachmentDefinition` named `storage-net` that attaches a secondary bridge `br1` on `192.168.100.0/24`.
3. Launch a pod that has its normal `eth0` **and** a second interface `net1` on the storage network, using the `k8s.v1.cni.cncf.io/networks` annotation.

Pod requirements:

Name: `dual-homed-pod`
Namespace: `default`
Image: `nicolaka/netshoot`
request storage-net as a secondary network using the `k8s.v1.cni.cncf.io/networks` annotation

The Pod must have its normal eth0 interface and a second net1 interface connected to the storage network.

## Success criteria

- `kubectl exec <pod> -- ip addr` shows both `eth0` and `net1`.
- `net1` has an address in `192.168.100.0/24`.
- The primary network (`eth0`) is unaffected - a plain pod without the annotation still only gets one interface.

## Official documentation

- Multus quickstart - https://github.com/k8snetworkplumbingwg/multus-cni/blob/master/docs/quickstart.md
- Multus configuration reference - https://github.com/k8snetworkplumbingwg/multus-cni/blob/master/docs/configuration.md
- CNI Specification - https://github.com/containernetworking/cni/blob/main/SPEC.md
