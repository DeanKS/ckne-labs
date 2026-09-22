#!/usr/bin/env bash
set -euo pipefail
echo "Installing Istio (demo profile, includes sidecar injection) and the Jaeger addon so this"
echo "scenario is actually reproducible rather than assuming a pre-existing mesh - this was a"
echo "gap flagged in review: don't lose prep time wondering why Jaeger isn't there."
echo

if ! command -v istioctl >/dev/null 2>&1; then
  echo "istioctl not found. Install it first: https://istio.io/latest/docs/setup/getting-started/#download"
  exit 1
fi

istioctl install --set profile=demo -y
kubectl label namespace default istio-injection=enabled --overwrite

# Pinned to a specific Istio release branch's addon manifest rather than main, for the same
# reproducibility reason as the cert-manager version pin elsewhere in this repo.
ISTIO_RELEASE_BRANCH="release-1.24"
kubectl apply -f "https://raw.githubusercontent.com/istio/istio/${ISTIO_RELEASE_BRANCH}/samples/addons/jaeger.yaml"
kubectl -n istio-system rollout status deployment/jaeger

echo
echo "Jaeger UI: kubectl -n istio-system port-forward svc/tracing 16686:80"
echo "Now deploy frontend/backend/db (reuse Deployments from earlier scenarios, e.g. mesh-lab,"
echo "or the Domain 2 orders-v1/orders-v2 services), inject a deliberate delay into exactly one"
echo "of them, and generate a request through the full chain before opening the UI."
