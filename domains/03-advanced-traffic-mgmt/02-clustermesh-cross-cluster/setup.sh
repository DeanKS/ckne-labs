#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CLUSTER1="ckne-mesh-1"
CLUSTER2="ckne-mesh-2"

CONTEXT1="kind-${CLUSTER1}"
CONTEXT2="kind-${CLUSTER2}"

CILIUM_VERSION="${CILIUM_VERSION:-1.18.2}"

echo "==> Creating ClusterMesh lab clusters"

if ! kind get clusters | grep -qx "${CLUSTER1}"; then
  kind create cluster \
    --name "${CLUSTER1}" \
    --config "${SCRIPT_DIR}/kind-cluster1.yaml"
else
  echo "Cluster ${CLUSTER1} already exists"
fi

if ! kind get clusters | grep -qx "${CLUSTER2}"; then
  kind create cluster \
    --name "${CLUSTER2}" \
    --config "${SCRIPT_DIR}/kind-cluster2.yaml"
else
  echo "Cluster ${CLUSTER2} already exists"
fi

CONTEXT1="kind-${CLUSTER1}"
CONTEXT2="kind-${CLUSTER2}"

echo
echo "==> Installing Cilium in ${CLUSTER1}"

cilium install \
  --version "${CILIUM_VERSION}" \
  --context "${CONTEXT1}" \
  --set cluster.name=cluster1 \
  --set cluster.id=1

echo
echo "==> Installing Cilium in ${CLUSTER2}"

cilium install \
  --version "${CILIUM_VERSION}" \
  --context "${CONTEXT2}" \
  --set cluster.name=cluster2 \
  --set cluster.id=2

echo
echo "==> Waiting for Cilium"

#cilium context "${CONTEXT1}" status --wait
#cilium context "${CONTEXT2}" status --wait
cilium status --context "${CONTEXT1}" --wait
cilium status --context "${CONTEXT2}" --wait

echo
echo "==> Creating test workloads"

kubectl --context "${CONTEXT1}" create namespace mesh-lab \
  --dry-run=client -o yaml |
  kubectl --context "${CONTEXT1}" apply -f -

kubectl --context "${CONTEXT2}" create namespace mesh-lab \
  --dry-run=client -o yaml |
  kubectl --context "${CONTEXT2}" apply -f -

kubectl --context "${CONTEXT1}" -n mesh-lab create deployment catalog \
  --image=nginx \
  --replicas=1 \
  --dry-run=client -o yaml |
  kubectl --context "${CONTEXT1}" apply -f -

kubectl --context "${CONTEXT2}" -n mesh-lab create deployment catalog \
  --image=nginx \
  --replicas=1 \
  --dry-run=client -o yaml |
  kubectl --context "${CONTEXT2}" apply -f -

kubectl --context "${CONTEXT1}" -n mesh-lab expose deployment catalog \
  --port=80 \
  --target-port=80 \
  --dry-run=client -o yaml |
  kubectl --context "${CONTEXT1}" apply -f -

kubectl --context "${CONTEXT2}" -n mesh-lab expose deployment catalog \
  --port=80 \
  --target-port=80 \
  --dry-run=client -o yaml |
  kubectl --context "${CONTEXT2}" apply -f -

echo
echo "==> Waiting for workloads"

kubectl --context "${CONTEXT1}" -n mesh-lab rollout status deployment/catalog --timeout=120s
kubectl --context "${CONTEXT2}" -n mesh-lab rollout status deployment/catalog --timeout=120s

echo
echo "============================================================"
echo "ClusterMesh lab environment ready"
echo "============================================================"
echo
echo "Cluster 1: ${CONTEXT1}"
echo "  Cilium cluster name: cluster1"
echo "  Cilium cluster ID:   1"
echo
echo "Cluster 2: ${CONTEXT2}"
echo "  Cilium cluster name: cluster2"
echo "  Cilium cluster ID:   2"
echo
echo "ClusterMesh has NOT been enabled."
echo "That is part of the candidate task."
echo
