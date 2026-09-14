#!/usr/bin/env bash
set -uo pipefail
pass=0; fail=0
check() { if eval "$2"; then echo "PASS: $1"; pass=$((pass+1)); else echo "FAIL: $1"; fail=$((fail+1)); fi; }

check "web-svc targetPort is 80" \
  "[ \"\$(kubectl -n svc-lab get svc web-svc -o jsonpath='{.spec.ports[0].targetPort}')\" = 80 ]"

READY=$(kubectl -n svc-lab get endpointslices -l kubernetes.io/service-name=web-svc \
  -o jsonpath='{.items[*].endpoints[*].conditions.ready}' 2>/dev/null)
check "all listed endpoints report ready=true" \
  "! echo '${READY}' | grep -q false"

CLUSTER_IP=$(kubectl -n svc-lab get svc web-svc -o jsonpath='{.spec.clusterIP}')
FAILS=0
for i in $(seq 1 20); do
  kubectl -n svc-lab run curl-test-$i --image=curlimages/curl --restart=Never --rm -i \
    --command -- curl -s -o /dev/null -w "%{http_code}" "http://${CLUSTER_IP}" 2>/dev/null | grep -q "^200" || FAILS=$((FAILS+1))
done
check "20/20 curl attempts to ClusterIP succeeded (failed: ${FAILS})" "[ ${FAILS} -eq 0 ]"

echo "---"; echo "${pass} passed, ${fail} failed"; exit $fail
