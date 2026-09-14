#!/usr/bin/env bash
set -euo pipefail
# Provision the secondary bridge on every worker node
for node in ckne-labs-worker ckne-labs-worker2; do
  docker exec "$node" sh -c '
    apk add --no-cache bridge-utils 2>/dev/null || true
    ip link add br1 type bridge 2>/dev/null || true
    ip link set br1 up
  '
done
echo "br1 bridges are up on worker nodes. Multus is NOT yet installed."
