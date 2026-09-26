# Scenario: Service Without a Selector + Manual EndpointSlice

**Domain:** Service Networking and DNS (25%)
**Competencies:** Configuring L4 Services · Configuring Pod Endpoint Availability

## Context

The platform team needs a stable in-cluster DNS name and ClusterIP, `external-api.svc-lab.svc.cluster.local`, for a legacy system that lives **outside** the cluster at `192.0.2.10:443`. There is no pod backing this - it must point at a fixed external address.

For this local lab, setup.sh provides an in-cluster external-stand-in Deployment to simulate the external system. Its pod IP represents the external backend address.
The external-api Service does not exist yet.

## Task

1. Create a Service named `external-api` in namespace `svc-lab` with **no selector**.
- `no selector`
- `a valid ClusterIP`
- `port 443/TCP`
2. Manually create the `EndpointSlice` for `external-api`, that provides its backend address, since Kubernetes will not generate one automatically for a selector-less Service. Create an `EndpointSlice` for `external-api`. The slice must be associated with the Service using the **correct label** and must contain at least one ready endpoint.
- Associate the EndpointSlice with `external-api` using the appropriate Service association label.
- Use the IP address of the `external-stand-in` pod as the endpoint address.
- Configure the endpoint as ready.
- Expose the backend on `port 443`.
3. Confirm DNS resolution and connectivity work from inside the cluster exactly as they would for a normal Service.

## Useful setup information

setup.sh creates the external-stand-in Deployment and external-stand-in-svc Service for local testing.

Find the stand-in pod IP with:

`kubectl -n svc-lab get pod -l app=external-stand-in -o wide`

The external-stand-in-svc Service is provided only as lab infrastructure; do not modify it or use it as the `external-api` Service.

## Success criteria

- `kubectl get svc external-api` shows no selector and a valid ClusterIP.
- `kubectl get endpointslices -l kubernetes.io/service-name=external-api` returns your manually created slice.
- `dig external-api.svc-lab.svc.cluster.local` from inside a pod resolves to the Service's ClusterIP.
- A `curl` to `https://external-api.svc-lab.svc.cluster.local` from inside the cluster reaches `192.0.2.10:443` (simulated locally - see `setup.sh`).

## Official documentation

- Services without selectors - https://kubernetes.io/docs/concepts/services-networking/service/#services-without-selectors
- EndpointSlices - https://kubernetes.io/docs/concepts/services-networking/endpoint-slices/
