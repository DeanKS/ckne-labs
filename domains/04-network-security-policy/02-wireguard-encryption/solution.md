# Solution: WireGuard Node Encryption

## Enable it

```bash
helm upgrade cilium cilium/cilium \
  --namespace kube-system \
  --reuse-values \
  --set encryption.enabled=true \
  --set encryption.type=wireguard

kubectl -n kube-system rollout restart ds/cilium
kubectl -n kube-system rollout status ds/cilium
```

`--reuse-values` matters here — a bare `helm upgrade` without it resets every other Cilium setting (CNI mode, kube-proxy replacement, IPAM) back to chart defaults, which is a good way to break a working cluster while "just" turning on encryption.

## Verify

```bash
kubectl -n kube-system exec ds/cilium -- cilium-dbg status | grep -A1 Encryption
```

Expect something like:

```
Encryption: Wireguard   [NodeEncryption: Enabled, cilium_wg0 (Pubkey: ..., Port: 51871, Peers: 2)]
```

`Peers: 2` on a 3-node cluster means this node has established WireGuard tunnels to both other nodes — if it shows fewer peers than `node count - 1`, at least one node's key exchange failed.

## Confirming it's actually encrypting, not just "enabled"

Capture on a node's external interface while generating cross-node pod traffic:

```bash
docker exec ckne-labs-worker tcpdump -i eth0 -n udp port 51871 -c 5
```

You should see UDP traffic on WireGuard's port between node IPs — and critically, if you instead capture with a filter for the *pod's own IPs and ports* on that same node interface, you should see nothing in cleartext, because the packet has already been encrypted and re-encapsulated by the time it leaves the node.

## Common failure modes

- Enabling encryption but not restarting the daemonset — Cilium doesn't always pick up crypto config changes from a live ConfigMap update without a pod restart, and you'll get a config that "looks enabled" in the Helm values but isn't reflected in `cilium-dbg status`.
- Testing same-node pod-to-pod traffic and being confused it isn't encrypted — this is correct behavior. WireGuard here operates node-to-node; two pods on the same node never leave that node's kernel, so there is nothing to encrypt.
- Firewall/security group rules on the underlying infrastructure blocking UDP/51871 between nodes — a very common real-world gap that a Kind lab won't surface but the exam's stated competency ("implementing," not just "enabling") implies you should be able to name.
