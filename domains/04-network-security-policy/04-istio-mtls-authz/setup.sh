#!/usr/bin/env bash
set -euo pipefail

echo "Prerequisites: The setup script installs Istio with the Ambient profile if Istio is not already present. The mesh-lab namespace is configured for Istio Ambient mode. No PeerAuthentication or AuthorizationPolicy is created by the setup script; these are intentionally left for the learner."

ISTIO_PROFILE="${ISTIO_PROFILE:-ambient}"

echo "==> Checking Kubernetes connectivity"
kubectl cluster-info >/dev/null

echo "==> Checking for istioctl"
if ! command -v istioctl >/dev/null 2>&1; then
  echo "ERROR: istioctl is required but was not found in PATH."
  echo "Install Istio/istioctl before running this lab."
  exit 1
fi

echo "==> Checking Istio installation"

if ! kubectl get crd peerauthentications.security.istio.io >/dev/null 2>&1; then
  echo "==> Istio CRDs not found; installing Istio with the ambient profile"

  istioctl install \
    --set profile="${ISTIO_PROFILE}" \
    --skip-confirmation
else
  echo "==> Istio CRDs already installed"
fi

echo "==> Waiting for Istio components"
kubectl wait \
  --for=condition=available \
  deployment/istiod \
  -n istio-system \
  --timeout=180s

echo "==> Verifying Istio CRDs"

kubectl get crd peerauthentications.security.istio.io
kubectl get crd authorizationpolicies.security.istio.io

echo "==> Creating mesh-lab namespace"

kubectl create namespace mesh-lab \
  --dry-run=client \
  -o yaml \
  | kubectl apply -f -

echo "==> Enabling Istio ambient mode for mesh-lab"

kubectl label namespace mesh-lab \
  istio.io/dataplane-mode=ambient \
  --overwrite

echo "==> Creating ServiceAccounts and workloads"

for app in frontend payments other-svc; do
  kubectl -n mesh-lab create serviceaccount "${app}-sa" \
    --dry-run=client \
    -o yaml \
    | kubectl apply -f -

  kubectl -n mesh-lab create deployment "$app" \
    --image=nginx \
    --dry-run=client \
    -o yaml \
    | kubectl apply -f -

  kubectl -n mesh-lab patch deployment "$app" \
    --type merge \
    -p "{\"spec\":{\"template\":{\"spec\":{\"serviceAccountName\":\"${app}-sa\"}}}}"

  kubectl -n mesh-lab expose deployment "$app" \
    --port=80 \
    --target-port=80 \
    2>/dev/null || true
done

echo
echo "==> Waiting for workloads"

kubectl -n mesh-lab rollout status deployment/frontend --timeout=120s
kubectl -n mesh-lab rollout status deployment/payments --timeout=120s
kubectl -n mesh-lab rollout status deployment/other-svc --timeout=120s

echo
echo "============================================================"
echo "mesh-lab ready"
echo "============================================================"
echo
echo "Istio ambient mode:"
kubectl get namespace mesh-lab --show-labels

echo
echo "Workloads:"
kubectl -n mesh-lab get pods,svc

echo
echo "No PeerAuthentication or AuthorizationPolicy has been applied."
echo "mTLS policy is intentionally left for the learner."
