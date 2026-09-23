# Solution: Reading the Access Log

## 1. Gateway-level failures vs. successes

Non-2xx entries:

| req_id | status | path | source | reading |
|---|---|---|---|---|
| a1b4-a1b8 | 404 | `/admin`, `/.env`, `/wp-admin`, `/.git/config`, `/api/v1/debug` | 198.51.100.9 | gateway-level rejects - `upstream=-` means these never even reached a backend; the gateway itself returned 404 because no route matched |
| a1c0 | 502 | `/api/orders` | 203.0.113.7 | this one **did** reach `orders-v2` (`upstream=orders-v2` is populated) and the upstream failed to respond correctly - a real backend problem, not a routing problem |

The distinction between `upstream=-` and a populated `upstream` field is the single most useful thing in this log format for separating "nothing was listening/routed" from "something was listening and broke."

## 2. Probing pattern

`198.51.100.9` hit five distinct nonexistent paths (`/admin`, `/.env`, `/wp-admin`, `/.git/config`, `/api/v1/debug`) within a 2-second window, all 404, all with near-identical low latency. One 404 from a mistyped URL is normal client behavior; five different well-known "interesting" paths from one source in rapid succession is a scanning/probing signature, not a typo. `203.0.113.5`, `.7`, and `.8`, by contrast, each hit exactly one legitimate-looking path - normal traffic.

## 3. The slowest request, and what the log can't tell you

`req_id=a1c0` at 3004ms is by far the slowest logged entry - nearly 10x the next-slowest (`a1c2` at 310ms). The access log tells you the *total* time the gateway waited for a response from `orders-v2`, and that it ended in a 502. It cannot tell you *why* - was `orders-v2` itself slow, was there a slow downstream dependency of `orders-v2`, was it a connection-level timeout with no real processing at all? A single latency number from an access log is exactly the kind of aggregate/black-box measurement that Domain 5's tracing scenario exists to get past - you'd take this same `req_id` (or the equivalent trace ID from the response headers, if the gateway propagates one) into Jaeger and look at the actual span breakdown to find out where inside that 3004ms the time went.

## Common failure modes

- Treating every 404 as equally uninteresting - the difference between "one 404 from a real user typo" and "five 404s to sensitive-looking paths from one source in two seconds" is exactly the "distinguish normal, rejected, and suspicious" skill this scenario is testing, and it's easy to skim past if you're only scanning for non-2xx codes rather than also grouping by source and time window.
- Confusing a 404 with a 502 as "both just failures" - a 404 with `upstream=-` means the gateway itself never routed the request anywhere; a 502 with a populated `upstream` means routing worked and the backend failed. These point you at completely different places to fix (a missing/misconfigured `HTTPRoute` vs. an unhealthy backend Deployment).
- Trying to diagnose *why* `a1c0` was slow using only this log - the access log's job ends at "it was slow and it failed"; going further requires tracing, and recognizing that boundary quickly is worth more under time pressure than staring at one log line hoping it'll reveal more than it structurally can.
