# Solution: Cilium CLI Install + Helm Value Mapping

## The mental model to hold onto

The `cilium` CLI does not talk to some separate Cilium-specific install mechanism — every `cilium install`/`cilium upgrade` invocation is generating and applying a Helm release under the hood (`cilium` chart, `kube-system` namespace by default). This is exactly why `helm get values cilium -n kube-system` always works afterward, regardless of whether you used `cilium install` or `helm install` directly — they're the same underlying object. Once you internalize that, "what Helm value does this CLI flag map to" stops being memorization and becomes "read the flag name, it's almost always the value path with dots instead of dashes."

## Fixing the install

Since Cilium is already installed (just misconfigured), use `cilium upgrade`, not `cilium install` again:

```bash
cilium upgrade \
  --set kubeProxyReplacement=true \
  --set hubble.enabled=true \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true

kubectl -n kube-system rollout status ds/cilium
kubectl -n kube-system rollout status deployment/hubble-relay
kubectl -n kube-system rollout status deployment/hubble-ui
```

## Mapping CLI flags to Helm values

| CLI flag | Helm value | What it actually does |
|---|---|---|
| `--set kubeProxyReplacement=true` | `kubeProxyReplacement: true` | Cilium's eBPF datapath takes over Service load-balancing instead of kube-proxy's iptables/ipvs rules |
| `--set hubble.enabled=true` | `hubble.enabled: true` | Turns on the observability pipeline (flow visibility) inside the Cilium agent itself |
| `--set hubble.relay.enabled=true` | `hubble.relay.enabled: true` | Deploys the cluster-wide aggregation point `hubble observe` / the UI actually query |
| `--set hubble.ui.enabled=true` | `hubble.ui.enabled: true` | Deploys the web UI on top of relay |

This is a 1:1 mapping in every case here — Cilium's CLI doesn't rename or restructure values, it passes `--set` straight through to Helm. That's true for the vast majority of `cilium install`/`upgrade` flags; the CLI's only real value-add over bare `helm install` is auto-detecting your cluster's pod CIDR, kube-proxy state, and a few networking defaults it would otherwise be tedious to specify by hand.

```bash
helm get values cilium -n kube-system
```

should show all four values above, confirming the CLI flags landed exactly where you'd expect.

## Verify

```bash
cilium status
kubectl get nodes    # all should be Ready now that CNI is fully up
cilium hubble ui &   # or: kubectl -n kube-system port-forward svc/hubble-ui 12000:80
```

## Common failure modes

- Running `cilium install` again on an already-installed cluster instead of `cilium upgrade` — this can leave the release in an inconsistent state; always check `cilium status` first to know which command you actually need.
- Enabling `hubble.enabled=true` but forgetting `hubble.relay.enabled=true` — the agent starts collecting flow data locally, but nothing aggregates it cluster-wide, so `hubble observe` from outside a single node's agent pod returns nothing.
- Assuming `kubeProxyReplacement=true` alone removes kube-proxy — it doesn't uninstall the existing kube-proxy DaemonSet for you; on a cluster where kube-proxy was already running (unlike this from-scratch Kind lab), you'd need to remove it separately once Cilium's replacement is confirmed healthy.
