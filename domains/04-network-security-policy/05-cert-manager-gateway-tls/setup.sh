#!/usr/bin/env bash
set -euo pipefail
# Pinned to a known-good release rather than /latest/ so this lab behaves the same way
# months from now — cert-manager's CRDs/behavior can shift between minor versions, and a
# reproducible exam-prep lab shouldn't silently drift underneath you.
CERT_MANAGER_VERSION="v1.16.2"
echo "Installing cert-manager ${CERT_MANAGER_VERSION}..."
kubectl apply -f "https://github.com/cert-manager/cert-manager/releases/download/${CERT_MANAGER_VERSION}/cert-manager.yaml"
kubectl -n cert-manager rollout status deployment/cert-manager
kubectl -n cert-manager rollout status deployment/cert-manager-webhook
echo "cert-manager ${CERT_MANAGER_VERSION} installed. Create a self-signed ClusterIssuer and a Certificate next — see task.md."
