#!/usr/bin/env bash
set -euo pipefail
kubectl create namespace gw-lab --dry-run=client -o yaml | kubectl apply -f -
kubectl -n gw-lab create deployment orders-v1 --image=hashicorp/http-echo --dry-run=client -o yaml -- -text="v1" | kubectl apply -f -
kubectl -n gw-lab create deployment orders-v2 --image=hashicorp/http-echo --dry-run=client -o yaml -- -text="v2" | kubectl apply -f -
kubectl -n gw-lab expose deployment orders-v1 --port=80 --target-port=5678
kubectl -n gw-lab expose deployment orders-v2 --port=80 --target-port=5678
echo "orders-v1/orders-v2 deployed. GatewayClass assumed pre-installed (e.g. Cilium, Envoy Gateway)."

echo "orders-v1/orders-v2 deployed."

echo "Checking Gateway API prerequisites..."

if ! kubectl api-resources --api-group=gateway.networking.k8s.io \
    | grep -q '^gatewayclasses'; then
  echo "ERROR: Gateway API CRDs are not installed." >&2
  echo "The CKNE lab cluster must be provisioned with Gateway API support." >&2
  exit 1
fi

echo "Available GatewayClasses:"
kubectl get gatewayclass

if ! kubectl get gatewayclass -o name | grep -q .; then
  echo "ERROR: No GatewayClass found." >&2
  echo "A Gateway API controller must be configured in the lab cluster." >&2
  echo "kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.6.1/standard-install.yaml" >&2
  echo "helm upgrade cilium cilium/cilium --version 1.18.2 --namespace kube-system --reuse-values --set gatewayAPI.enabled=true" >&2
  echo "kubectl -n kube-system rollout status deployment/cilium-operator" >&2
  echo "kubectl -n kube-system rollout status daemonset/cilium" >&2
  exit 1
fi
