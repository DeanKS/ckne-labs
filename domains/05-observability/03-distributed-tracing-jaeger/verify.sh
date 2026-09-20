#!/usr/bin/env bash
set -uo pipefail
echo "This scenario is verified visually in the Jaeger UI rather than programmatically."
echo "Confirm manually:"
echo "  1. A trace exists spanning frontend -> backend -> db (three services, one trace ID)."
echo "  2. You can name which specific span holds the majority of self-time (not total time)."
echo "  3. Re-run after 'fixing' your identified bottleneck and confirm total trace duration drops."
echo
echo "Automated check: confirm the tracing backend itself is reachable."
kubectl -n istio-system get svc tracing >/dev/null 2>&1 && echo "PASS: Jaeger service reachable" || echo "FAIL: Jaeger service not found — check setup.sh"
