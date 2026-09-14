#!/usr/bin/env bash
set -euo pipefail
kubectl create namespace svc-lab --dry-run=client -o yaml | kubectl apply -f -

cat << 'YAML' | kubectl -n svc-lab apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  replicas: 3
  selector:
    matchLabels: {app: web}
  template:
    metadata:
      labels: {app: web}
    spec:
      containers:
      - name: web
        image: nginx
        ports:
        - containerPort: 8080
        readinessProbe:
          tcpSocket:
            port: 9999   # BUG: wrong port, will always fail on 1/3 pods after a forced restart
          periodSeconds: 30
          failureThreshold: 5
        livenessProbe:
          tcpSocket:
            port: 80
---
apiVersion: v1
kind: Service
metadata:
  name: web-svc
spec:
  selector: {app: web}
  ports:
  - port: 80
    targetPort: 8080
YAML
echo "svc-lab namespace ready. Investigate why web-svc drops ~1/3 of requests."
