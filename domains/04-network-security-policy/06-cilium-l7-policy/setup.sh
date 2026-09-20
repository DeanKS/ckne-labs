#!/usr/bin/env bash
set -euo pipefail
kubectl create namespace l7-lab --dry-run=client -o yaml | kubectl apply -f -
kubectl -n l7-lab create deployment api --image=kennethreitz/httpbin --dry-run=client -o yaml | kubectl apply -f -
kubectl -n l7-lab create deployment frontend --image=curlimages/curl --dry-run=client -o yaml -- sleep infinity | kubectl apply -f -
kubectl -n l7-lab expose deployment api --port=8080 --target-port=80
kubectl -n l7-lab label deployment api app=api --overwrite
kubectl -n l7-lab label deployment frontend app=frontend --overwrite
echo "l7-lab ready: frontend can currently GET/POST/DELETE freely against api. Lock it down to GET only."
