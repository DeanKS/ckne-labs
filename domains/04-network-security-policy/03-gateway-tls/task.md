# Scenario: TLS Termination and Backend TLS on the Gateway API

**Domain:** Network Security and Policy (25%)
**Competencies:** Managing TLS Certificates for Gateway API · Implementing Pod-level Authentication and Authorization

## Context

`public-gw` (from Domain 2, scenario 3) currently serves plaintext HTTP. Two new requirements:

1. External clients must connect over HTTPS using a certificate stored in a Kubernetes `Secret`.
2. Traffic from the Gateway to the `orders-v2` backend must itself be encrypted with TLS (the backend serves HTTPS on port 8443, with a certificate signed by a private CA), not just terminated-and-forwarded in cleartext.

## Task

1. Add an HTTPS listener to `public-gw` on port 443 that terminates TLS using a Secret named `orders-tls`.
2. Configure a `BackendTLSPolicy` so the Gateway validates `orders-v2`'s certificate against the private CA before forwarding traffic to it over TLS.
3. Ensure the `ServiceAccount` used by `orders-v2` pods has only the RBAC permissions it actually needs (read its own ConfigMaps, nothing cluster-wide).

## Success criteria

- `curl -k https://<gw-ip>/orders` succeeds over TLS.
- Plaintext HTTP to the same path either redirects to HTTPS or is disabled, per your design choice (state which you picked).
- Gateway-to-backend hop uses TLS validated against the supplied CA bundle, not `insecureSkipVerify`.
- `orders-v2`'s ServiceAccount cannot list Secrets or Pods outside its own namespace.
