# Scenario: Default-Deny NetworkPolicy with Explicit Allows

**Domain:** Network Security and Policy (25%)
**Competencies:** Securing Traffic with Network Policies

## Context

Namespace `secure-app` has `frontend`, `backend`, and `db` deployments. Today anything can talk to anything. You need to lock it down.

## Task

1. Default-deny all ingress and egress in `secure-app`.
2. Allow `frontend` → `backend` on TCP/8080 only.
3. Allow `backend` → `db` on TCP/5432 only.
4. Allow DNS egress (UDP/TCP 53) from all pods to `kube-system`, since default-deny egress otherwise breaks DNS resolution.
5. `frontend` must remain reachable from outside the cluster (ingress from anywhere on port 80).

## Success criteria

- `frontend` cannot reach `db` directly.
- `backend` can reach `db` on 5432; cannot reach anything else.
- DNS still resolves inside every pod in the namespace.
- External clients can still reach `frontend` on port 80.
