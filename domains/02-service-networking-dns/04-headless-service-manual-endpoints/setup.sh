#!/usr/bin/env bash
set -euo pipefail
kubectl create namespace svc-lab --dry-run=client -o yaml | kubectl apply -f -

# Stand in for the "external" 192.0.2.10 target with a real in-cluster pod so this is
# testable on a local Kind cluster - in a real exam environment this IP would genuinely
# be off-cluster and you'd only be able to verify DNS/Service plumbing, not connectivity.
kubectl -n svc-lab create deployment external-stand-in --image=nginx --dry-run=client -o yaml | kubectl apply -f -
kubectl -n svc-lab expose deployment external-stand-in --port=443 --target-port=80 --name=external-stand-in-svc
echo "Note: this lab uses a real in-cluster pod as a stand-in for the '192.0.2.10' external target."
echo "Find its actual pod IP with: kubectl -n svc-lab get pod -l app=external-stand-in -o wide"
