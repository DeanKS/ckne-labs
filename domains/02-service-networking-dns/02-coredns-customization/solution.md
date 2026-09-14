# Solution: Custom CoreDNS Forwarding

## Why a separate server block, not a rewrite rule

CoreDNS routes queries to the most specific matching zone block, most-specific-first, independent of file order — so adding a dedicated `ext-ai.com:53 { forward . 1.1.1.1 }` block is enough on its own; you don't need `rewrite` or a `template` plugin, and you must not touch the existing `.:53` block's `kubernetes` plugin or its own `forward . /etc/resolv.conf` fallback, since that's what keeps ordinary external names and cluster Services working.

## Steps

```bash
kubectl -n kube-system edit configmap coredns
```

Resulting `Corefile` data:

```
Corefile: |
    .:53 {
        errors
        health
        ready
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           fallthrough in-addr.arpa ip6.arpa
        }
        prometheus :9153
        forward . /etc/resolv.conf
        cache 30
        loop
        reload
        loadbalance
    }
    ext-ai.com:53 {
        errors
        cache 30
        forward . 1.1.1.1
    }
```

Only the second block is new — everything under `.:53` is untouched from the default install.

```bash
kubectl -n kube-system rollout restart deployment coredns
kubectl -n kube-system rollout status deployment coredns
```

## Verify

```bash
kubectl run dns-test --image=tutum/dnsutils --rm -it --restart=Never -- sh -c \
  "dig +short ext-ai.com; dig +short kubernetes.default.svc.cluster.local; dig +short google.com"
```

All three should return answers. If `ext-ai.com` times out, check that the CoreDNS pods can actually reach `1.1.1.1` — a restrictive `CiliumNetworkPolicy`/`NetworkPolicy` on `kube-system` is a common reason this silently fails in a hardened cluster (see Domain 4).

## Common failure modes

- Editing the ConfigMap live with `kubectl edit` but forgetting `rollout restart` — CoreDNS doesn't hot-reload the Corefile from a ConfigMap change by default unless the `kubernetes` plugin's `reload` directive is present (it watches the *file*, mounted via ConfigMap, and does eventually pick it up — but relying on that instead of an explicit restart is a common source of "why isn't my change taking effect" during a timed exam).
- Putting the `ext-ai.com` block *inside* `.:53` instead of as its own server block — CoreDNS server blocks are keyed by zone+port, and a forward directive nested under the wrong zone won't match.
- Forgetting `fallthrough` semantics only matter within the `kubernetes` plugin for in-cluster PTR records — it has no bearing on the new external zone block.
