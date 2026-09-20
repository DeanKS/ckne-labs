#!/usr/bin/env bash
set -euo pipefail
echo "Assumes a service mesh with tracing enabled (Istio + Jaeger, or Cilium + Hubble tracing"
echo "exported to Jaeger) is already installed, and Jaeger's UI is reachable."
echo
echo "If using Istio's addon Jaeger for a local lab:"
echo "  kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.24/samples/addons/jaeger.yaml"
echo "  kubectl -n istio-system port-forward svc/tracing 16686:80 &"
echo
echo "One of the three services in this lab has an artificial delay injected (a sleep before"
echo "responding) to simulate the kind of latency this scenario asks you to isolate — deploy"
echo "frontend/backend/db yourself with that in mind, or reuse Deployments from earlier scenarios"
echo "and add a deliberate delay to exactly one of them before starting."
