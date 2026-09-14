#!/usr/bin/env bash
set -euo pipefail
kubectl create namespace gw-lab --dry-run=client -o yaml | kubectl apply -f -
kubectl -n gw-lab create deployment orders-v1 --image=hashicorp/http-echo -- -text="v1" --dry-run=client -o yaml | kubectl apply -f -
kubectl -n gw-lab create deployment orders-v2 --image=hashicorp/http-echo -- -text="v2" --dry-run=client -o yaml | kubectl apply -f -
kubectl -n gw-lab expose deployment orders-v1 --port=80 --target-port=5678
kubectl -n gw-lab expose deployment orders-v2 --port=80 --target-port=5678
echo "orders-v1/orders-v2 deployed. GatewayClass assumed pre-installed (e.g. Cilium, Envoy Gateway)."
echo "Available GatewayClasses:"
kubectl get gatewayclass
