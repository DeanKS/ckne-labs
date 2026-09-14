# Solution: Manual CNI Bridge + IPAM

## Why this shape

CNI plugins are meant to be chained: the `bridge` type owns interface creation and IPAM delegation, and any plugin further down the chain (like `tuning`) receives the already-configured interface and layers additional behavior on top — it never re-runs IPAM. That chaining, and the ADD/DEL/CHECK contract each plugin implements, is the core idea in the CNI SPEC (see `docs/resource-map.md`).

## Steps

On **every** node (Kind nodes are containers — `docker exec` into each one):

```bash
for node in ckne-labs-control-plane ckne-labs-worker ckne-labs-worker2; do
  docker exec "$node" mkdir -p /etc/cni/net.d
  docker exec -i "$node" tee /etc/cni/net.d/10-dbnet.conflist > /dev/null << 'JSON'
{
  "cniVersion": "1.1.0",
  "name": "dbnet",
  "plugins": [
    {
      "type": "bridge",
      "bridge": "cni0",
      "isGateway": true,
      "ipMasq": true,
      "ipam": {
        "type": "host-local",
        "subnet": "10.1.0.0/16",
        "gateway": "10.1.0.1"
      }
    },
    {
      "type": "tuning",
      "sysctl": {
        "net.core.somaxconn": "500"
      }
    }
  ]
}
JSON
done
```

`isGateway` and `ipMasq` aren't spelled out in the exam prompt, but without them the bridge has no address to act as gateway and outbound traffic isn't NATed — the pod gets an IP but nothing reaches it or leaves it. That gap between "the JSON matches the prompt" and "the pod actually passes traffic" is exactly what `verify.sh` checks for.

Delete and recreate the test pod so the kubelet retries CNI ADD against the new config:

```bash
kubectl delete pod cni-test-pod --force --grace-period=0
kubectl run cni-test-pod --image=nginx --restart=Never
```

## Common failure modes

- The file must be a **`.conflist`** (multiple plugins), not a `.conf` — some CNI versions silently ignore a `"plugins"` array inside a `.conf` file.
- `/etc/cni/net.d/` is read in lexical filename order and only the **first** valid file is used. A stray `05-*.conflist` from an earlier attempt beats your `10-dbnet.conflist`.
- IPAM state lives in `/var/lib/cni/networks/dbnet/` on the host. If you change the subnet mid-lab, stale lease files there hand out addresses from the old range — clear that directory when the subnet changes.
