#!/usr/bin/env bash
set -euo pipefail
kubectl run cni-test-pod --image=nginx --restart=Never
echo "Pod created. It will stay in ContainerCreating until you configure the CNI."
echo "Nodes: $(kubectl get nodes -o name | tr '\n' ' ')"
