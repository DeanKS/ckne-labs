# Scenario: cert-manager Issuing TLS for a Gateway Listener

**Domain:** Network Security and Policy (25%)
**Competencies:** Managing TLS Certificates for Gateway API

## Context

`domains/04-network-security-policy/03-gateway-tls` used a hand-rolled, self-signed Secret for the Gateway's HTTPS listener — fine for understanding the `Gateway`/`Secret` relationship, but not how certificates are actually managed in practice. Real-world CKNE feedback (`docs/exam-strategy.md`) specifically flags cert-manager's Gateway API integration as exam-relevant.

## Task

1. Install cert-manager and a self-signed `ClusterIssuer` (standing in for a real ACME/CA issuer in this local lab).
2. Create a `Certificate` resource that tells cert-manager to keep a Secret named `orders-tls-managed` populated and renewed automatically.
3. Point `public-gw`'s HTTPS listener at that managed Secret instead of the manually created one.
4. Explain what happens to the Gateway if the Certificate is deleted or fails to renew — don't just make the happy path work.

## Success criteria

- `kubectl get certificate orders-tls-managed -n gw-lab` shows `READY: True`.
- The Secret referenced by the `Gateway`'s HTTPS listener is the cert-manager-managed one, not the one from scenario 03.
- You can state, from `kubectl describe certificate`, roughly when the certificate is due to renew.

## Official documentation

- cert-manager Gateway API integration — https://cert-manager.io/docs/usage/gateway/
- Gateway API TLS guide — https://gateway-api.sigs.k8s.io/guides/user-guides/tls/
