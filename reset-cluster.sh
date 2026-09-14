#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-ckne-labs}"

kind delete cluster --name "${CLUSTER_NAME}"
docker system prune -f
echo "Environment clean. Ready for a fresh attempt."
