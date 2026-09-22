# Solution: Manual CNI Bridge + IPAM

## Why this shape

CNI plugins are meant to be chained: the `bridge` type owns interface creation and IPAM delegation, and any plugin further down the chain (like `tuning`) receives the already-configured interface and layers additional behavior on top - it never re-runs IPAM. That chaining, and the ADD/DEL/CHECK contract each plugin implements, is the core idea in the CNI SPEC (see `docs/resource-map.md`).

## Steps

On **every** node (Kind nodes are containers - `docker exec` into each one):

```bash
for node in ckne-labs-control-plane ckne-labs-worker ckne-labs-worker2; do
  docker exec "$node" mkdir -p /etc/cni/net.d
  docker exec -i "$node" tee /etc/cni/net.d/10-dbnet.conflist > /dev/null << 'JSON'
{
  "cniVersion": "1.0.0",
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

`isGateway` and `ipMasq` aren't spelled out in the exam prompt, but without them the bridge has no address to act as gateway and outbound traffic isn't NATed - the pod gets an IP but nothing reaches it or leaves it. That gap between "the JSON matches the prompt" and "the pod actually passes traffic" is exactly what `verify.sh` checks for.

## Why `cniVersion: 1.0.0`, not `1.1.0`

This was found by actually running this scenario against a live Kind cluster (containerd 2.1.x), not assumed. CNI spec `1.1.0` introduced a new `STATUS` operation that runtimes can invoke to check network readiness without spinning up a real container. Modern containerd versions use `STATUS` for exactly this when a node's CNI config declares `1.1.0`+. If the installed plugin binaries don't fully implement `STATUS` dispatch, the runtime can fall through to a code path that expects `CNI_CONTAINERID` to be set - which `STATUS` deliberately never sets, since there's no real container - and kubelet reports the node `NotReady` with the unhelpful message `Network plugin returns error: missing containerID`. Declaring `1.0.0` avoids triggering `STATUS` entirely and sidesteps the issue. If you're troubleshooting a similar failure on a different runtime/plugin combination in the future, this is worth checking before assuming your conflist syntax is wrong - the JSON can be perfectly correct and still fail this way purely on version-negotiation grounds.

Delete and recreate the test pod so the kubelet retries CNI ADD against the new config:

```bash
kubectl delete pod cni-test-pod --force --grace-period=0
kubectl run cni-test-pod --image=nginx --restart=Never
```

## Common failure modes

- The file must be a **`.conflist`** (multiple plugins), not a `.conf` - some CNI versions silently ignore a `"plugins"` array inside a `.conf` file.
- `/etc/cni/net.d/` is read in lexical filename order and only the **first** valid file is used. A stray `05-*.conflist` from an earlier attempt beats your `10-dbnet.conflist`.
- IPAM state lives in `/var/lib/cni/networks/dbnet/` on the host. If you change the subnet mid-lab, stale lease files there hand out addresses from the old range - clear that directory when the subnet changes.
- **Missing plugin binaries**, not a bad conflist, is the single most likely reason nodes stay `NotReady` after you think you've done everything right. `journalctl -u kubelet | grep -i cni` on the affected node will say `failed to find plugin "bridge" in path [/opt/cni/bin]` if this is what's happening - `setup.sh` installs `bridge` and `tuning` for you in this scenario, but if you're troubleshooting a similar setup elsewhere, check this before re-reading your JSON for the fifth time.
- **`missing containerID`** in the `Ready` condition's message is the `cniVersion`/`STATUS`-command issue described above, not a conflist syntax problem - don't go looking for a JSON typo if you see this exact message.
