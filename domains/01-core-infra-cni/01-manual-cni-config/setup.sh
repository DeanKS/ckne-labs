#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NODES="${CLUSTER_NODES:-ckne-labs-control-plane ckne-labs-worker ckne-labs-worker2}"
CNI_PLUGINS_VERSION="v1.5.1"

# Kind's node image ships only a minimal default set of CNI plugin binaries
# (host-local, loopback, portmap, ptp) — bridge and tuning, which this scenario
# needs, are not among them. Install the missing two on every node before the
# candidate ever touches a conflist, so the task is genuinely just "write the
# correct config," not "also discover a missing-binary problem first."
ARCH=$(docker exec ckne-labs-control-plane uname -m)
case "$ARCH" in
  aarch64) CNI_ARCH="arm64" ;;
  x86_64)  CNI_ARCH="amd64" ;;
  *) echo "Unrecognized node architecture: $ARCH — install cni-plugins manually for this arch." >&2; exit 1 ;;
esac

TMPDIR=$(mktemp -d)
curl -sL -o "${TMPDIR}/cni-plugins.tgz" \
  "https://github.com/containernetworking/plugins/releases/download/${CNI_PLUGINS_VERSION}/cni-plugins-linux-${CNI_ARCH}-${CNI_PLUGINS_VERSION}.tgz"
tar -xzf "${TMPDIR}/cni-plugins.tgz" -C "${TMPDIR}"

for node in $CLUSTER_NODES; do
  need_bridge=$(docker exec "$node" sh -c '[ -x /opt/cni/bin/bridge ] && echo yes || echo no')
  need_tuning=$(docker exec "$node" sh -c '[ -x /opt/cni/bin/tuning ] && echo yes || echo no')
  if [ "$need_bridge" = "no" ]; then
    docker cp "${TMPDIR}/bridge" "${node}:/opt/cni/bin/bridge"
    docker exec "$node" chmod +x /opt/cni/bin/bridge
  fi
  if [ "$need_tuning" = "no" ]; then
    docker cp "${TMPDIR}/tuning" "${node}:/opt/cni/bin/tuning"
    docker exec "$node" chmod +x /opt/cni/bin/tuning
  fi
done
rm -rf "${TMPDIR}"

echo "bridge and tuning CNI binaries confirmed present on: ${CLUSTER_NODES}"

kubectl run cni-test-pod --image=nginx --restart=Never
echo "Pod created. It will stay in ContainerCreating until you configure the CNI conflist."
echo "Nodes: $(kubectl get nodes -o name | tr '\n' ' ')"
