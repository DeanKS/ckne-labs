#!/usr/bin/env bash
set -euo pipefail
kubectl create namespace secure-app --dry-run=client -o yaml | kubectl apply -f -
for app in frontend backend db; do
  kubectl -n secure-app create deployment "$app" --image=nginx --dry-run=client -o yaml | \
    kubectl -n secure-app apply -f -
  kubectl -n secure-app label deployment "$app" app="$app" --overwrite
  kubectl -n secure-app patch deployment "$app" --type merge -p \
    "{\"spec\":{\"template\":{\"metadata\":{\"labels\":{\"app\":\"$app\"}}}}}"
done
echo "secure-app namespace deployed with no NetworkPolicies yet - everything can reach everything."
