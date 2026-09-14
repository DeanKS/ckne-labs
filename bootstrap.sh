#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-ckne-labs}"

kind create cluster --config kind-config.yaml --name "${CLUSTER_NAME}"
kubectl cluster-info --context "kind-${CLUSTER_NAME}"

echo
echo "Cluster '${CLUSTER_NAME}' provisioned. Nodes will show NotReady until a CNI"
echo "is installed — that's expected. Start with domains/01-core-infra-cni/."
