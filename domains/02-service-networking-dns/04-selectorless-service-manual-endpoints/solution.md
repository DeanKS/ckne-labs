# Solution: Selector-less Service + Manual EndpointSlice

## Why this is a real gotcha, not just a syntax exercise

A normal Service's `selector` tells the EndpointSlice controller which pods to watch and keep the slice in sync with automatically. Remove the selector and that controller has nothing to watch - Kubernetes does **not** fall back to creating an empty slice or inferring anything. If you only create the Service and stop there, DNS will resolve to a ClusterIP that goes nowhere, and there will be no error telling you why - this is exactly the kind of task that looks like a two-second fix and silently fails if you forget step 2 entirely.

## Manifests

```yaml
apiVersion: v1
kind: Service
metadata:
  name: external-api
  namespace: svc-lab
spec:
  ports:
    - port: 443
      targetPort: 443
---
apiVersion: discovery.k8s.io/v1
kind: EndpointSlice
metadata:
  name: external-api-1
  namespace: svc-lab
  labels:
    kubernetes.io/service-name: external-api   # this label is what ties the slice to the Service
addressType: IPv4
ports:
  - port: 443
endpoints:
  - addresses:
      - 192.0.2.10   # replace with your stand-in pod's real IP for this local lab
```

Note there is deliberately **no `selector`** on the Service - that's what makes this scenario distinct from every other Service task in this repo.

## The one label that makes or breaks this

`kubernetes.io/service-name: external-api` on the `EndpointSlice` is the only thing linking the two objects together - there's no `spec` field on the Service pointing at the slice; the relationship is entirely label-driven, in the other direction from what most people expect coming from ordinary Service/Deployment pairs.

## Verify

```bash
kubectl -n svc-lab get svc external-api -o yaml | grep -A2 spec  # confirm no selector
kubectl -n svc-lab get endpointslices -l kubernetes.io/service-name=external-api
kubectl -n svc-lab run dns-test --image=tutum/dnsutils --rm -it --restart=Never -- \
  dig +short external-api.svc-lab.svc.cluster.local
```

## Common failure modes

- Creating the Service and assuming a slice appears - it never will, by design, for a selector-less Service.
- Forgetting the `kubernetes.io/service-name` label, or misspelling it - the slice exists but is invisible to the Service; `kubectl get endpoints external-api` will show nothing even though your EndpointSlice object is sitting right there.
- Trying to add a `selector` back "to be safe" - as soon as a Service has a selector, Kubernetes' own EndpointSlice controller takes over reconciliation and will fight with (and eventually delete) any manually created slice that doesn't match real pods.
