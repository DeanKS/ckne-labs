#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="mesh-lab"
ISTIO_NAMESPACE="istio-system"
CILIUM_NAMESPACE="kube-system"

# CKNE lab kind cluster nodes.
# Used only for runtime Cilium validation.
CLUSTER_NODES=(
  ckne-labs-control-plane
  ckne-labs-worker
  ckne-labs-worker2
)

echo "=============================================="
echo " Istio Ambient mTLS/AuthZ Lab Setup"
echo "=============================================="
echo

###############################################################################
# Helpers
###############################################################################

get_cilium_pod_for_node() {
  local node="$1"

  kubectl -n "$CILIUM_NAMESPACE" get pods \
    -l k8s-app=cilium \
    --field-selector="spec.nodeName=${node}" \
    -o jsonpath='{.items[0].metadata.name}' \
    2>/dev/null || true
}

###############################################################################
# Kubernetes connectivity
###############################################################################

echo "==> Checking Kubernetes connectivity"

kubectl cluster-info >/dev/null

echo "    Kubernetes connectivity OK ✓"

###############################################################################
# istioctl
###############################################################################

echo "==> Checking for istioctl"

if ! command -v istioctl >/dev/null 2>&1; then
  echo "ERROR: istioctl is required but was not found in PATH."
  echo
  echo "Install istioctl before running this lab:"
  echo "  https://istio.io/latest/docs/ambient/install/istioctl/"
  exit 1
fi

ISTIOCTL_VERSION="$(
  istioctl version --remote=false 2>/dev/null |
    head -1 || true
)"

echo "    istioctl found: ${ISTIOCTL_VERSION:-unknown} ✓"

###############################################################################
# Cilium compatibility checks
###############################################################################

echo "==> Checking Cilium/Istio compatibility"

if ! kubectl -n "$CILIUM_NAMESPACE" get configmap cilium-config \
    >/dev/null 2>&1; then

  echo "    Cilium config not detected; continuing."

else

  ###########################################################################
  # cni.exclusive
  ###########################################################################

  CNI_EXCLUSIVE="$(
    kubectl -n "$CILIUM_NAMESPACE" get configmap cilium-config \
      -o jsonpath='{.data.cni-exclusive}' \
      2>/dev/null || true
  )"

  if [[ "$CNI_EXCLUSIVE" != "false" ]]; then

    echo
    echo "ERROR: Cilium is not configured for Istio CNI coexistence."
    echo
    echo "Current cni-exclusive value:"
    echo "  ${CNI_EXCLUSIVE:-<not set>}"
    echo
    echo "Istio Ambient requires Cilium to run with:"
    echo "  cni.exclusive=false"
    echo
    echo "Fix the Cilium prerequisite with:"
    echo
    echo "  helm upgrade cilium cilium/cilium \\"
    echo "    -n kube-system \\"
    echo "    --version 1.18.2 \\"
    echo "    --reuse-values \\"
    echo "    --set cni.exclusive=false \\"
    echo "    --wait"
    echo
    echo "Then verify:"
    echo
    echo "  kubectl -n kube-system get cm cilium-config \\"
    echo "    -o jsonpath='{.data.cni-exclusive}{\"\\n\"}'"
    echo
    echo "Expected:"
    echo "  false"
    echo
    echo "This setup script deliberately does not modify the existing"
    echo "Cilium installation because Cilium is shared infrastructure."
    exit 1
  fi

  echo "    cni-exclusive=false ✓"

  ###########################################################################
  # kube-proxy replacement / socketLB
  ###########################################################################

  SOCKET_LB_HOSTNS="$(
    kubectl -n "$CILIUM_NAMESPACE" get configmap cilium-config \
      -o jsonpath='{.data.bpf-lb-sock-hostns-only}' \
      2>/dev/null || true
  )"

  KUBE_PROXY_REPLACEMENT="$(
    kubectl -n "$CILIUM_NAMESPACE" get configmap cilium-config \
      -o jsonpath='{.data.kube-proxy-replacement}' \
      2>/dev/null || true
  )"

  if [[ "$KUBE_PROXY_REPLACEMENT" == "true" ]] && \
     [[ "$SOCKET_LB_HOSTNS" != "true" ]]; then

    echo
    echo "ERROR: Cilium kube-proxy replacement is enabled, but"
    echo "socketLB.hostNamespaceOnly is not enabled."
    echo
    echo "Current values:"
    echo "  kube-proxy-replacement: ${KUBE_PROXY_REPLACEMENT}"
    echo "  bpf-lb-sock-hostns-only: ${SOCKET_LB_HOSTNS:-<not set>}"
    echo
    echo "Istio Ambient requires socket-based load balancing to be"
    echo "restricted to the host namespace when Cilium replaces kube-proxy."
    echo
    echo "Fix the Cilium prerequisite with:"
    echo
    echo "  helm upgrade cilium cilium/cilium \\"
    echo "    -n kube-system \\"
    echo "    --version 1.18.2 \\"
    echo "    --reuse-values \\"
    echo "    --set cni.exclusive=false \\"
    echo "    --set socketLB.hostNamespaceOnly=true \\"
    echo "    --wait"
    echo
    exit 1
  fi

  if [[ "$KUBE_PROXY_REPLACEMENT" == "true" ]]; then
    echo "    kube-proxy replacement detected"
    echo "    socketLB.hostNamespaceOnly=true ✓"
  fi

  ###########################################################################
  # BPF masquerading
  ###########################################################################

  BPF_MASQUERADE="$(
    kubectl -n "$CILIUM_NAMESPACE" get configmap cilium-config \
      -o jsonpath='{.data.enable-bpf-masquerade}' \
      2>/dev/null || true
  )"

  if [[ "$BPF_MASQUERADE" == "true" ]]; then

    echo
    echo "ERROR: Cilium BPF masquerading is enabled."
    echo
    echo "Istio Ambient does not support bpf.masquerade=true."
    echo
    echo "Disable BPF masquerading in the Cilium Helm configuration"
    echo "before running this lab."
    echo
    echo "The lab will not modify Cilium automatically."
    exit 1
  fi

  echo "    BPF masquerading is compatible ✓"

fi

###############################################################################
# Cilium runtime CNI validation
#
# The ConfigMap can report:
#
#   cni-exclusive=false
#
# while an already-running Cilium agent is still operating with its previous
# configuration. This can cause Cilium to rename Istio's CNI configuration.
###############################################################################

echo
echo "==> Checking Cilium runtime CNI state"

CILIUM_RUNTIME_FAILURE=false

for node in "${CLUSTER_NODES[@]}"; do

  cilium_pod="$(get_cilium_pod_for_node "$node")"

  if [[ -z "$cilium_pod" ]]; then
    echo "    ${node}: ERROR - no Cilium pod found"
    CILIUM_RUNTIME_FAILURE=true
    continue
  fi

  echo "    ${node}: ${cilium_pod}"

  CNI_EXCLUSIVE_RUNTIME="$(
    kubectl -n "$CILIUM_NAMESPACE" exec "$cilium_pod" -- \
      sh -c 'cat /tmp/cilium/config-map/cni-exclusive 2>/dev/null || true' \
      2>/dev/null || true
  )"

  if [[ -n "$CNI_EXCLUSIVE_RUNTIME" ]] && \
     [[ "$CNI_EXCLUSIVE_RUNTIME" != "false" ]]; then

    echo "      runtime cni-exclusive: ${CNI_EXCLUSIVE_RUNTIME}"
    CILIUM_RUNTIME_FAILURE=true

  else

    echo "      runtime cni-exclusive: false ✓"

  fi

done

if [[ "$CILIUM_RUNTIME_FAILURE" == "true" ]]; then

  echo
  echo "ERROR: One or more Cilium agents are not configured for"
  echo "Istio CNI coexistence."
  echo
  echo "The Cilium ConfigMap may already contain:"
  echo "  cni-exclusive=false"
  echo
  echo "but the running Cilium agents have not necessarily picked"
  echo "up the new configuration."
  echo
  echo "Restart Cilium and rerun this setup script:"
  echo
  echo "  kubectl -n kube-system rollout restart ds/cilium"
  echo "  kubectl -n kube-system rollout status ds/cilium"
  echo
  echo "The lab deliberately does not perform this restart automatically."
  exit 1

fi

###############################################################################
# Check Cilium logs for known CNI conflict
###############################################################################

echo
echo "==> Checking Cilium logs for CNI configuration conflicts"

CNI_RENAME_FAILURE=false

for node in "${CLUSTER_NODES[@]}"; do

  cilium_pod="$(get_cilium_pod_for_node "$node")"

  [[ -z "$cilium_pod" ]] && continue

  if kubectl -n "$CILIUM_NAMESPACE" logs "$cilium_pod" \
      --since=10m 2>/dev/null |
      grep -q "Renaming non-Cilium CNI configuration file"; then

    echo "    ${node}: CNI rename activity detected"
    CNI_RENAME_FAILURE=true

  else

    echo "    ${node}: no recent CNI rename activity ✓"

  fi

done

if [[ "$CNI_RENAME_FAILURE" == "true" ]]; then

  echo
  echo "ERROR: Cilium has recently renamed a non-Cilium CNI configuration."
  echo
  echo "This indicates that the running Cilium agents are still behaving"
  echo "as though CNI exclusivity is enabled."
  echo
  echo "Restart Cilium and rerun this setup script:"
  echo
  echo "  kubectl -n kube-system rollout restart ds/cilium"
  echo "  kubectl -n kube-system rollout status ds/cilium"
  echo
  exit 1

fi

###############################################################################
# Istio installation
###############################################################################

echo
echo "==> Checking Istio installation"

ISTIO_PODS_EXIST=false

if kubectl get namespace "$ISTIO_NAMESPACE" \
    >/dev/null 2>&1; then

  if kubectl -n "$ISTIO_NAMESPACE" get pods \
      -l app=istiod \
      --no-headers 2>/dev/null |
      grep -q .; then

    ISTIO_PODS_EXIST=true

  fi

fi

if [[ "$ISTIO_PODS_EXIST" == "true" ]]; then

  echo "    Existing Istio control plane detected."
  echo "    Upgrading Istio to the ambient profile."

  istioctl upgrade \
    --set profile=ambient \
    --skip-confirmation

else

  echo "    No existing Istio control plane detected."
  echo "    Installing Istio with the ambient profile."

  istioctl install \
    --set profile=ambient \
    --skip-confirmation

fi

###############################################################################
# Wait for Istio components
###############################################################################

echo
echo "==> Waiting for Istio components"

kubectl -n "$ISTIO_NAMESPACE" rollout status \
  deployment/istiod \
  --timeout=180s

kubectl -n "$ISTIO_NAMESPACE" rollout status \
  daemonset/istio-cni-node \
  --timeout=180s

kubectl -n "$ISTIO_NAMESPACE" rollout status \
  daemonset/ztunnel \
  --timeout=180s

echo "    Istio control plane ready ✓"
echo "    Istio CNI ready ✓"
echo "    ztunnel ready ✓"

###############################################################################
# Create lab namespace
###############################################################################

echo
echo "==> Creating lab namespace"

kubectl create namespace "$NAMESPACE" \
  --dry-run=client \
  -o yaml |
  kubectl apply -f -

###############################################################################
# Enable Ambient mode
###############################################################################

echo "==> Enabling Istio Ambient mode"

kubectl label namespace "$NAMESPACE" \
  istio.io/dataplane-mode=ambient \
  --overwrite

echo "    Ambient mode enabled ✓"

###############################################################################
# ServiceAccounts
###############################################################################

echo "==> Creating ServiceAccounts"

for app in frontend payments other-svc; do

  service_account="${app}-sa"

  kubectl -n "$NAMESPACE" create serviceaccount "$service_account" \
    --dry-run=client \
    -o yaml |
    kubectl apply -f -

done

###############################################################################
# Workloads
###############################################################################

echo "==> Creating workloads"

for app in frontend payments other-svc; do

  service_account="${app}-sa"

  if kubectl -n "$NAMESPACE" get deployment "$app" \
      >/dev/null 2>&1; then

    echo "    ${app}: existing deployment found; updating."

  else

    echo "    ${app}: creating deployment."

  fi

  kubectl -n "$NAMESPACE" create deployment "$app" \
    --image=nginx \
    --dry-run=client \
    -o yaml |
    kubectl -n "$NAMESPACE" apply -f -

  kubectl -n "$NAMESPACE" patch deployment "$app" \
    --type merge \
    -p "{\"spec\":{\"template\":{\"spec\":{\"serviceAccountName\":\"${service_account}\"}}}}"

  kubectl -n "$NAMESPACE" expose deployment "$app" \
    --port=80 \
    --target-port=80 \
    --dry-run=client \
    -o yaml |
    kubectl -n "$NAMESPACE" apply -f -

done

###############################################################################
# Wait for workloads
###############################################################################

echo
echo "==> Waiting for workloads"

for app in frontend payments other-svc; do

  kubectl -n "$NAMESPACE" rollout status \
    deployment/"$app" \
    --timeout=180s

done

###############################################################################
# Verify Ambient workload enrollment
###############################################################################

echo
echo "==> Verifying Ambient workload enrollment"

ZTUNNEL_WORKLOADS="$(
  istioctl ztunnel-config workloads \
    -n "$ISTIO_NAMESPACE" \
    2>/dev/null || true
)"

for app in frontend payments other-svc; do

  POD_NAME="$(
    kubectl -n "$NAMESPACE" get pods \
      -l "app=${app}" \
      -o jsonpath='{.items[0].metadata.name}' \
      2>/dev/null || true
  )"

  if [[ -z "$POD_NAME" ]]; then
    echo "    ${app}: ERROR - pod not found"
    echo
    echo "ERROR: Could not find a pod for ${app}."
    echo
    echo "Check:"
    echo
    echo "  kubectl get pods -n ${NAMESPACE}"
    echo
    exit 1
  fi

  AMBIENT_STATUS="$(
    echo "$ZTUNNEL_WORKLOADS" |
      awk -v ns="$NAMESPACE" -v pod="$POD_NAME" '
        $1 == ns && $2 == pod && $6 == "HBONE" {
          print "true"
          exit
        }
      '
  )"

  if [[ "$AMBIENT_STATUS" == "true" ]]; then

    echo "    ${app}: enrolled in Ambient (HBONE) ✓"

  else

    echo "    ${app}: NOT enrolled in Ambient"

    echo
    echo "ERROR: ${POD_NAME} was not detected by ztunnel using HBONE."
    echo
    echo "Check:"
    echo
    echo "  kubectl get pods -n ${NAMESPACE} -o wide"
    echo
    echo "  istioctl ztunnel-config workloads -n ${ISTIO_NAMESPACE}"
    echo
    exit 1

  fi

done

###############################################################################
# Final status
###############################################################################

echo
echo "=============================================="
echo " Ambient Istio lab ready"
echo "=============================================="
echo
echo "Namespace:"
echo "  $NAMESPACE"
echo
echo "Ambient mode:"
echo "  istio.io/dataplane-mode=ambient"
echo
echo "Workloads:"
echo "  frontend"
echo "  payments"
echo "  other-svc"
echo
echo "ServiceAccounts:"
echo "  frontend-sa"
echo "  payments-sa"
echo "  other-svc-sa"
echo
echo "Istio components:"
echo "  istiod"
echo "  istio-cni-node"
echo "  ztunnel"
echo
echo "Cilium:"
echo "  cni-exclusive=false"
echo "  runtime CNI coexistence verified"
echo
echo "No PeerAuthentication or AuthorizationPolicy has been"
echo "created. The lab starts without the required security"
echo "policies so the candidate must implement them."
echo
echo "Useful verification:"
echo
echo "  kubectl get namespace $NAMESPACE --show-labels"
echo
echo "  kubectl get pods -n $NAMESPACE"
echo
echo "  istioctl ztunnel-config workloads -n $ISTIO_NAMESPACE"
echo
echo "  kubectl get authorizationpolicy,peerauthentication -n $NAMESPACE"
echo
echo "Next step: implement STRICT mTLS and the payments"
echo "AuthorizationPolicy described in task.md."
echo
