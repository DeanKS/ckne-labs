#!/usr/bin/env bash
set -euo pipefail
# Self-signed cert/key for the Gateway's HTTPS listener
openssl req -x509 -nodes -newkey rsa:2048 -days 30 \
  -keyout /tmp/tls.key -out /tmp/tls.crt -subj "/CN=orders.example.com" 2>/dev/null
kubectl -n gw-lab create secret tls orders-tls --cert=/tmp/tls.crt --key=/tmp/tls.key \
  --dry-run=client -o yaml | kubectl apply -f -

# A ConfigMap holding the private CA bundle used to validate the backend's cert
kubectl -n gw-lab create configmap orders-ca --from-file=ca.crt=/tmp/tls.crt \
  --dry-run=client -o yaml | kubectl apply -f -

echo "orders-tls Secret and orders-ca ConfigMap created in gw-lab."
