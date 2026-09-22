# Scenario: Service Without a Selector + Manual EndpointSlice

**Domain:** Service Networking and DNS (25%)
**Competencies:** Configuring L4 Services · Configuring Pod Endpoint Availability

## Context

The platform team needs a stable in-cluster DNS name and ClusterIP, `external-api.svc-lab.svc.cluster.local`, for a legacy system that lives **outside** the cluster at `192.0.2.10:443`. There is no pod backing this - it must point at a fixed external address.

## Task

1. Create a Service named `external-api` in namespace `svc-lab` with **no selector**.
2. Manually create the `EndpointSlice` that provides its backend address, since Kubernetes will not generate one automatically for a selector-less Service.
3. Confirm DNS resolution and connectivity work from inside the cluster exactly as they would for a normal Service.

## Success criteria

- `kubectl get svc external-api` shows no selector and a valid ClusterIP.
- `kubectl get endpointslices -l kubernetes.io/service-name=external-api` returns your manually created slice.
- `dig external-api.svc-lab.svc.cluster.local` from inside a pod resolves to the Service's ClusterIP.
- A `curl` to `https://external-api.svc-lab.svc.cluster.local` from inside the cluster reaches `192.0.2.10:443` (simulated locally - see `setup.sh`).

## Official documentation

- Services without selectors - https://kubernetes.io/docs/concepts/services-networking/service/#services-without-selectors
- EndpointSlices - https://kubernetes.io/docs/concepts/services-networking/endpoint-slices/
