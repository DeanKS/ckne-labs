#!/usr/bin/env bash
set -uo pipefail

pass=0
fail=0

check() {
  if eval "$2"; then
    echo "PASS: $1"
    pass=$((pass+1))
  else
    echo "FAIL: $1"
    fail=$((fail+1))
  fi
}

CLUSTER1="kind-ckne-mesh-1"
CLUSTER2="kind-ckne-mesh-2"

echo "=== ClusterMesh Cross-Cluster Verification ==="
echo

# ---------------------------------------------------------------------------
# Cluster availability
# ---------------------------------------------------------------------------

check "cluster1 exists and is reachable" \
  "kubectl --context ${CLUSTER1} cluster-info >/dev/null 2>&1"

check "cluster2 exists and is reachable" \
  "kubectl --context ${CLUSTER2} cluster-info >/dev/null 2>&1"

# ---------------------------------------------------------------------------
# Cilium health
# ---------------------------------------------------------------------------

#check "Cilium is healthy in cluster1" \
#  "cilium context "${CLUSTER1}" status --wait >/dev/null 2>&1"
#
#check "Cilium is healthy in cluster2" \
#  "cilium context "${CLUSTER2}" status --wait >/dev/null 2>&1"

check "Cilium is healthy in cluster1" \
  "cilium status --context ${CLUSTER1} --wait >/dev/null 2>&1"

check "Cilium is healthy in cluster2" \
  "cilium status --context ${CLUSTER2} --wait >/dev/null 2>&1"

# ---------------------------------------------------------------------------
# ClusterMesh connectivity
# ---------------------------------------------------------------------------

#check "ClusterMesh is connected in cluster1" \
#  "cilium context ${CLUSTER1} clustermesh status --wait >/dev/null 2>&1"
#
#check "ClusterMesh is connected in cluster2" \
#  "cilium context ${CLUSTER2} clustermesh status  --wait >/dev/null 2>&1"

check "ClusterMesh is connected in cluster1" \
  "cilium clustermesh status --context ${CLUSTER1} --wait >/dev/null 2>&1"

check "ClusterMesh is connected in cluster2" \
  "cilium clustermesh status --context ${CLUSTER2} --wait >/dev/null 2>&1"

# ---------------------------------------------------------------------------
# Global Service
# ---------------------------------------------------------------------------

check "catalog-svc exists in cluster1" \
  "kubectl --context ${CLUSTER1} -n mesh-lab get svc catalog-svc >/dev/null 2>&1"

check "catalog-svc exists in cluster2" \
  "kubectl --context ${CLUSTER2} -n mesh-lab get svc catalog-svc >/dev/null 2>&1"

check "catalog-svc is configured as a Global Service in cluster1" \
  "[ \"$(kubectl --context ${CLUSTER1} -n mesh-lab get svc catalog-svc -o jsonpath='{.metadata.annotations.service\\.cilium\\.io/global}' 2>/dev/null)\" = \"true\" ]"

check "catalog-svc is configured as a Global Service in cluster2" \
  "[ \"$(kubectl --context ${CLUSTER2} -n mesh-lab get svc catalog-svc -o jsonpath='{.metadata.annotations.service\\.cilium\\.io/global}' 2>/dev/null)\" = \"true\" ]"

# ---------------------------------------------------------------------------
# ClusterMesh service backends
# ---------------------------------------------------------------------------

check "catalog-svc has a local backend in cluster1" \
  "kubectl --context ${CLUSTER1} -n mesh-lab get endpointslice -l kubernetes.io/service-name=catalog-svc -o json 2>/dev/null | grep -q 'addresses'"

check "catalog-svc has a local backend in cluster2" \
  "kubectl --context ${CLUSTER2} -n mesh-lab get endpointslice -l kubernetes.io/service-name=catalog-svc -o json 2>/dev/null | grep -q 'addresses'"

# ---------------------------------------------------------------------------
# Cilium service state
# ---------------------------------------------------------------------------

check "catalog-svc is present in Cilium service map in cluster1" \
  "kubectl --context ${CLUSTER1} -n kube-system exec ds/cilium -- cilium-dbg service list 2>/dev/null | grep -q 'catalog-svc'"

check "catalog-svc is present in Cilium service map in cluster2" \
  "kubectl --context ${CLUSTER2} -n kube-system exec ds/cilium -- cilium-dbg service list 2>/dev/null | grep -q 'catalog-svc'"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

echo
echo "---"
echo "${pass} passed, ${fail} failed"

exit "$fail"
