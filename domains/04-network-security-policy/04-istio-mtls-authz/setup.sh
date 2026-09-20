#!/usr/bin/env bash
set -euo pipefail
echo "Assumes Istio is already installed (istioctl install) with sidecar injection enabled."
kubectl create namespace mesh-lab --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace mesh-lab istio-injection=enabled --overwrite

for app in frontend payments other-svc; do
  kubectl -n mesh-lab create serviceaccount "$app-sa" --dry-run=client -o yaml | kubectl apply -f -
  kubectl -n mesh-lab create deployment "$app" --image=nginx --dry-run=client -o yaml | kubectl apply -f -
  kubectl -n mesh-lab patch deployment "$app" --type merge -p \
    "{\"spec\":{\"template\":{\"spec\":{\"serviceAccountName\":\"$app-sa\"}}}}"
  kubectl -n mesh-lab expose deployment "$app" --port=80 --target-port=80 2>/dev/null || true
done

echo "mesh-lab ready: frontend, payments, and other-svc, each on their own ServiceAccount."
echo "No PeerAuthentication or AuthorizationPolicy applied yet — mTLS is currently PERMISSIVE (default)."
