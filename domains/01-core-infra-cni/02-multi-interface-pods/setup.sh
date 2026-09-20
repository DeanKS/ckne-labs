#!/usr/bin/env bash
set -euo pipefail

CNI_PLUGINS_VERSION="v1.5.1"

# The secondary network in this scenario also uses the "bridge" CNI type, delegated to by
# Multus. Kind's node image doesn't ship that binary by default (same gap as
# domains/01-core-infra-cni/01-manual-cni-config) — install it here too, independent of
# whichever primary CNI (Cilium, Calico, etc.) is already running.
ARCH=$(docker exec ckne-labs-worker uname -m)
case "$ARCH" in
  aarch64) CNI_ARCH="arm64" ;;
  x86_64)  CNI_ARCH="amd64" ;;
  *) echo "Unrecognized node architecture: $ARCH — install cni-plugins manually for this arch." >&2; exit 1 ;;
esac

TMPDIR=$(mktemp -d)
curl -sL -o "${TMPDIR}/cni-plugins.tgz" \
  "https://github.com/containernetworking/plugins/releases/download/${CNI_PLUGINS_VERSION}/cni-plugins-linux-${CNI_ARCH}-${CNI_PLUGINS_VERSION}.tgz"
tar -xzf "${TMPDIR}/cni-plugins.tgz" -C "${TMPDIR}"

# Provision the secondary bridge and the bridge binary on every worker node
for node in ckne-labs-worker ckne-labs-worker2; do
  docker exec "$node" sh -c '
    apk add --no-cache bridge-utils 2>/dev/null || true
    ip link add br1 type bridge 2>/dev/null || true
    ip link set br1 up
  '
  need_bridge=$(docker exec "$node" sh -c '[ -x /opt/cni/bin/bridge ] && echo yes || echo no')
  if [ "$need_bridge" = "no" ]; then
    docker cp "${TMPDIR}/bridge" "${node}:/opt/cni/bin/bridge"
    docker exec "$node" chmod +x /opt/cni/bin/bridge
  fi
done
rm -rf "${TMPDIR}"

echo "br1 bridges and the bridge CNI binary are ready on worker nodes. Multus is NOT yet installed."
