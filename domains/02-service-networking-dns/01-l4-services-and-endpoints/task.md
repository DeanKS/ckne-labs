# Scenario: L4 Services, kube-proxy Modes, and Endpoint Availability

**Domain:** Service Networking and DNS (25%)
**Competencies:** Configuring L4 Services · Understanding kube-proxy and CNI Alternatives · Troubleshooting Service Network Traffic · Configuring Pod Endpoint Availability

## Context

A `Deployment` named `web` (3 replicas, port 8080) exists in namespace `svc-lab`. A `ClusterIP` Service `web-svc` targets it on port `80`. Users report intermittent `Connection refused` — roughly 1 in 3 requests fails.

## Task

1. Diagnose why the Service intermittently fails, using `EndpointSlices` — not just `kubectl get endpoints`.
2. Fix it so all traffic sent to `web-svc:80` reaches a genuinely ready backend.
3. Without changing replica count, ensure a pod that fails its readiness probe is removed from the Service's routable set within 5 seconds of failing.

## Success criteria

- `kubectl get endpointslices -l kubernetes.io/service-name=web-svc` lists exactly the ready pods.
- 20 consecutive `curl` calls to the Service ClusterIP all succeed.
- The readiness probe's `periodSeconds`/`failureThreshold` combination guarantees removal within 5s of a real failure.

## Official documentation

- Service concept — https://kubernetes.io/docs/concepts/services-networking/service/
- Virtual IPs and Service proxies (kube-proxy modes) — https://kubernetes.io/docs/reference/networking/virtual-ips/
- EndpointSlices — https://kubernetes.io/docs/concepts/services-networking/endpoint-slices/
