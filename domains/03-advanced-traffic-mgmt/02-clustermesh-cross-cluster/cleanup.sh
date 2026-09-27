#!/usr/bin/env bash
set -euo pipefail

CLUSTER1="ckne-mesh-1"
CLUSTER2="ckne-mesh-2"

echo "==> Deleting ClusterMesh lab clusters"

kind delete cluster --name "${CLUSTER1}" || true
kind delete cluster --name "${CLUSTER2}" || true

echo
echo "==> ClusterMesh lab cleanup complete"
