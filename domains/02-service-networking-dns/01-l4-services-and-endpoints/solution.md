# Solution: L4 Services, Endpoint Availability

## Diagnosis

`nginx` listens on port 80 by default, not 8080 - the Deployment's `containerPort: 8080` is cosmetic; nothing in the container is actually bound to it. `targetPort: 8080` on the Service means two-thirds of the time you get lucky and hit... nothing, actually - every pod is equally broken, so this isn't a "some replicas work" bug, it's a "the Service is pointed at a port nothing listens on" bug. (If you only tested with `kubectl get endpoints` you'd see all 3 pods listed as endpoints, because container readiness - as configured - checks a TCP port that isn't the traffic port either, so it can pass or fail independently of whether the *Service* port is right. This is the trap: readiness ≠ correctness of the Service's targetPort.)

Separately, the readiness probe checks `tcpSocket: 9999`, a port nothing listens on, with `periodSeconds: 30` - even once the targetPort is fixed, a genuinely unhealthy pod would take up to 30s × failureThreshold before leaving rotation, which fails the "within 5 seconds" requirement.

## Fix

```bash
kubectl -n svc-lab patch svc web-svc --type merge -p '{"spec":{"ports":[{"port":80,"targetPort":80}]}}'

kubectl -n svc-lab patch deployment web --type json -p '[
  {"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe","value":{
    "tcpSocket": {"port": 80},
    "periodSeconds": 2,
    "failureThreshold": 2,
    "timeoutSeconds": 1
  }}
]'
```

`periodSeconds: 2` × `failureThreshold: 2` = worst case 4s to detect + a moment for the EndpointSlice controller to react - comfortably under the 5s bar. Going tighter (e.g. `periodSeconds: 1`) works too but adds probe overhead for no exam benefit.

## Verifying via EndpointSlices, not just endpoints

```bash
kubectl -n svc-lab get endpointslices -l kubernetes.io/service-name=web-svc -o yaml
```

Check `endpoints[].conditions.ready` per-address - this is what kube-proxy (or the CNI's eBPF datapath, if you're on Cilium in "kube-proxy replacement" mode) actually programs into the dataplane. The plain `Endpoints` object is kept for backwards compatibility but EndpointSlices are the source of truth kube-proxy watches, and they carry the `ready`/`serving`/`terminating` conditions that the older `Endpoints` API can't express - this is exactly why the exam competency singles out EndpointSlices rather than Endpoints.

## kube-proxy modes note (for the competency, not this specific bug)

`kubectl -n kube-system get cm kube-proxy -o yaml | grep mode` tells you if you're on `iptables` or `ipvs` mode - or, if the CNI (Cilium) runs in kube-proxy replacement mode, kube-proxy may not be doing the work at all and you should check `cilium status | grep KubeProxyReplacement` instead. Don't assume iptables rules exist just because a Service does.
