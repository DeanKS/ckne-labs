# Solution: Flow Log Auditing with Hubble

## Why `hubble observe -f` alone doesn't satisfy the ask

`hubble observe --follow` only shows what streams past while it's running, and Hubble's own per-node buffer is bounded and rotates — restart the relay or the agent and history before that point is gone. "Evidence... over the last hour" needs something durable, which means either exporting flows to a log sink or querying Hubble Relay's own retained buffer within its retention window (not something to rely on for real audit requirements).

## Export flows persistently

```bash
helm upgrade cilium cilium/cilium --namespace kube-system --reuse-values \
  --set hubble.export.static.enabled=true \
  --set hubble.export.static.filePath=/var/run/cilium/hubble/events.log
kubectl -n kube-system rollout restart ds/cilium
```

This writes every flow (subject to any configured filters) as JSON lines to a file on each node, which you'd typically ship off-node with a log forwarder (Fluent Bit, Vector, etc.) in a real cluster — for this lab, read it directly:

```bash
kubectl -n kube-system exec ds/cilium -- \
  cat /var/run/cilium/hubble/events.log | grep '"verdict":"DROPPED"'
```

## Filtered live view for `secure-app`

```bash
kubectl -n kube-system exec ds/cilium -- \
  hubble observe --namespace secure-app --verdict DROPPED -f
```

Each line includes source/destination pod identity, port, and (critically) which `NetworkPolicy` produced the verdict — look for the `policy-verdict` or `drop_reason` fields in the JSON export; in the CLI's human-readable form it appears as `DENIED` alongside the offending policy name (Cilium's own `CiliumNetworkPolicy` if applied at that layer; for stock `NetworkPolicy` objects there's no single "producing policy" attribution — Cilium reports the drop but attributes it to policy enforcement in aggregate, not per-object, since standard `NetworkPolicy` doesn't have per-rule audit IDs the way `CiliumNetworkPolicy` does).

## Answering "which pair, which policy"

```bash
kubectl -n kube-system exec ds/cilium -- hubble observe \
  --namespace secure-app --verdict DROPPED --protocol tcp -o json \
  | jq -r '"\(.source.pod_name) -> \(.destination.pod_name):\(.l4.TCP.destination_port) verdict=\(.verdict)"'
```

For this scenario that should surface `frontend-xxxx -> db-xxxx:80 verdict=DROPPED`, matching exactly what `default-deny-all` plus the absence of a `frontend`→`db` allow rule in Domain 4's policy set should produce.

## Common failure modes

- Relying on `kubectl logs` on the app pods themselves — application logs show a failed/timed-out connection attempt from the client's point of view, but never tell you *why* (policy vs. actual outage vs. DNS failure); Hubble is the layer that can distinguish those, which is the entire reason this is tested as its own competency separate from generic pod log reading.
- Forgetting that `hubble.export.static` writes **per-node** files — a drop between pods on different nodes will show up in the exporting node's own file for whichever side is local to it, not necessarily both; for a real multi-node audit you'd centralize via a log shipper rather than reading one node's file and assuming it's complete.
