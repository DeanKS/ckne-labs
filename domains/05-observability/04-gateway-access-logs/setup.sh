#!/usr/bin/env bash
set -euo pipefail

cat > sample-access.log << 'LOG'
2026-09-20T10:00:01Z req_id=a1b2 src=203.0.113.5 method=GET path=/api/users status=200 upstream=orders-v1 latency_ms=42
2026-09-20T10:00:02Z req_id=a1b3 src=203.0.113.5 method=GET path=/api/orders status=200 upstream=orders-v1 latency_ms=38
2026-09-20T10:00:04Z req_id=a1b4 src=198.51.100.9 method=GET path=/admin status=404 upstream=- latency_ms=3
2026-09-20T10:00:04Z req_id=a1b5 src=198.51.100.9 method=GET path=/.env status=404 upstream=- latency_ms=2
2026-09-20T10:00:05Z req_id=a1b6 src=198.51.100.9 method=GET path=/wp-admin status=404 upstream=- latency_ms=3
2026-09-20T10:00:05Z req_id=a1b7 src=198.51.100.9 method=GET path=/.git/config status=404 upstream=- latency_ms=2
2026-09-20T10:00:06Z req_id=a1b8 src=198.51.100.9 method=GET path=/api/v1/debug status=404 upstream=- latency_ms=3
2026-09-20T10:00:09Z req_id=a1b9 src=203.0.113.5 method=POST path=/api/orders status=201 upstream=orders-v1 latency_ms=55
2026-09-20T10:00:15Z req_id=a1c0 src=203.0.113.7 method=GET path=/api/orders status=502 upstream=orders-v2 latency_ms=3004
2026-09-20T10:00:20Z req_id=a1c1 src=203.0.113.5 method=GET path=/api/users status=200 upstream=orders-v1 latency_ms=40
2026-09-20T10:00:22Z req_id=a1c2 src=203.0.113.8 method=GET path=/api/orders status=200 upstream=orders-v2 latency_ms=310
LOG

echo "sample-access.log generated. Analyze it per task.md - do not regenerate traffic first."
