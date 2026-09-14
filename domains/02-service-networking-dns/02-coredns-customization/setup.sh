#!/usr/bin/env bash
set -euo pipefail
# Simulate the external target so dig has something real to resolve against 1.1.1.1
# (no actual setup needed beyond a stock CoreDNS install — this is a pure config task)
kubectl -n kube-system get cm coredns -o yaml | grep -A2 "Corefile:" || true
echo "Stock CoreDNS ConfigMap is in place. Edit it to add ext-ai.com forwarding."
