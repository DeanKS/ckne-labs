#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="mesh-lab"
ISTIO_NAMESPACE="istio-system"

echo "==> Checking Kubernetes connectivity"
kubectl cluster-info >/dev/null

echo "==> Checking for istioctl"
if ! command -v istioctl >/dev/null 2>&1; then
  echo "ERROR: istioctl is required but was not found in PATH."
  echo
  echo "Install istioctl before running this lab:"
  echo "  https://istio.io/latest/docs/ambient/install/istioctl/"
  exit 1
fi

echo "==> Checking Cilium/Istio compatibility"

if kubectl -n kube-system get configmap cilium-config >/dev/null 2>&1; then
  CNI_EXCLUSIVE="$(
    kubectl -n kube-system get configmap cilium-config \
      -o jsonpath='{.data.cni-exclusive}' 2>/dev/null || true
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
    echo "Your Cilium installation is Helm-managed as:"
    echo "  release:  cilium"
    echo "  namespace: kube-system"
    echo
    echo "Fix the Cilium prerequisite with:"
    echo
    echo "  helm upgrade cilium cilium/cilium \\"
    echo "    -n kube-system \\"
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
    echo "Cilium installation because Cilium is shared infrastructure"
    echo "and changing its configuration automatically could affect"
    echo "other CKNE labs."
    exit 1
  fi

  echo "    cni-exclusive=false ✓"

  SOCKET_LB_HOSTNS="$(
    kubectl -n kube-system get configmap cilium-config \
      -o jsonpath='{.data.bpf-lb-sock-hostns-only}' 2>/dev/null || true
  )"

  KUBE_PROXY_REPLACEMENT="$(
    kubectl -n kube-system get configmap cilium-config \
      -o jsonpath='{.data.kube-proxy-replacement}' 2>/dev/null || true
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
else
  echo "    Cilium config not detected; continuing."
fi

echo "==> Checking Cilium BPF masquerading compatibility"

BPF_MASQUERADE="$(
  kubectl -n kube-system get configmap cilium-config \
    -o jsonpath='{.data.enable-bpf-masquerade}' 2>/dev/null || true
)"

if [[ "$BPF_MASQUERADE" == "true" ]]; then
  echo
  echo "ERROR: Cilium BPF masquerading is enabled."
  echo
  echo "Istio currently does not support bpf.masquerade=true with"
  echo "Ambient mode because it can break Kubernetes health checks."
  echo
  echo "Disable BPF masquerading in the Cilium Helm configuration"
  echo "before running this lab."
  echo
  echo "The lab will not modify Cilium automatically."
  exit 1
fi

echo "    BPF masquerading is compatible ✓"

echo "==> Checking Istio installation"

ISTIO_PODS_EXIST=false

if kubectl get namespace "$ISTIO_NAMESPACE" >/dev/null 2>&1; then
  if kubectl -n "$ISTIO_NAMESPACE" get pods \
      -l app=istiod >/dev/null 2>&1 && \
     kubectl -n "$ISTIO_NAMESPACE" get pods \
      -l app=istiod --no-headers 2>/dev/null | grep -q .; then
    ISTIO_PODS_EXIST=true
  fi
fi

if [[ "$ISTIO_PODS_EXIST" == "true" ]]; then
  echo "    Existing Istio installation detected."
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

echo "==> Creating lab namespace"

kubectl create namespace "$NAMESPACE" \
  --dry-run=client \
  -o yaml | kubectl apply -f -

echo "==> Enabling Istio Ambient mode"

kubectl label namespace "$NAMESPACE" \
  istio.io/dataplane-mode=ambient \
  --overwrite

echo "==> Creating ServiceAccounts and workloads"

for app in frontend payments other-svc; do
  service_account="${app}-sa"

  kubectl -n "$NAMESPACE" create serviceaccount "$service_account" \
    --dry-run=client \
    -o yaml | kubectl apply -f -

  kubectl -n "$NAMESPACE" create deployment "$app" \
    --image=nginx \
    --dry-run=client \
    -o yaml | kubectl apply -f -

  kubectl -n "$NAMESPACE" patch deployment "$app" \
    --type merge \
    -p "{\"spec\":{\"template\":{\"spec\":{\"serviceAccountName\":\"${service_account}\"}}}}"

  kubectl -n "$NAMESPACE" expose deployment "$app" \
    --port=80 \
    --target-port=80 \
    2>/dev/null || true
done

echo "==> Waiting for workloads"

for app in frontend payments other-svc; do
  kubectl -n "$NAMESPACE" rollout status \
    deployment/"$app" \
    --timeout=180s
done

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
echo "No PeerAuthentication or AuthorizationPolicy has been"
echo "created. The lab starts without the required security"
echo "policies so the candidate must implement them."
echo
echo "Useful verification:"
echo
echo "  kubectl get namespace $NAMESPACE --show-labels"
echo
echo "  istioctl ztunnel-config workloads -n $ISTIO_NAMESPACE"
echo
echo "  kubectl get pods -n $NAMESPACE"
echo
echo "Next step: implement STRICT mTLS and the payments"
echo "AuthorizationPolicy described in task.md."
