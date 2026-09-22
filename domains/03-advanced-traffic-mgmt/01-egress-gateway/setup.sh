#!/usr/bin/env bash
set -euo pipefail
kubectl create namespace ai-workload --dry-run=client -o yaml | kubectl apply -f -
kubectl label node ckne-labs-worker egress-node=true --overwrite
echo "Namespace and gateway node label are ready."
echo "NOTE: Cilium Egress Gateway requires Cilium as CNI with egressGateway.enabled=true."
echo "It is NOT compatible with ClusterMesh enabled on the same datapath - don't enable both."
