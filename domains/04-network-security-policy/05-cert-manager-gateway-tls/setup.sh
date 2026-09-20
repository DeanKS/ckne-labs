#!/usr/bin/env bash
set -euo pipefail
echo "Installing cert-manager..."
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml
kubectl -n cert-manager rollout status deployment/cert-manager
kubectl -n cert-manager rollout status deployment/cert-manager-webhook
echo "cert-manager installed. Create a self-signed ClusterIssuer and a Certificate next — see task.md."
