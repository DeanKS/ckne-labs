# CKNE Labs

Hands-on lab repository for the [Certified Kubernetes Network Engineer (CKNE)](https://training.linuxfoundation.org/certification/certified-kubernetes-network-engineer-ckne/) exam, structured the same way as community repos for CKA/CKAD/CKS (setup → task → solution → verify), but organized around CKNE's actual five domains and weights.

> **CKNE is currently in beta** (as of writing: online, proctored, performance-based, 2 hours, $99 beta price, one free retake). Domain weights and task wording can still change before general availability — check the [official page](https://training.linuxfoundation.org/certification/certified-kubernetes-network-engineer-ckne/) before you sit the exam.

## Domain weighting (official)

| # | Domain | Weight | Directory |
|---|---|---|---|
| 1 | Core Infrastructure and CNI | 15% | [`domains/01-core-infra-cni`](domains/01-core-infra-cni) |
| 2 | Service Networking and DNS | 25% | [`domains/02-service-networking-dns`](domains/02-service-networking-dns) |
| 3 | Advanced Traffic Management | 20% | [`domains/03-advanced-traffic-mgmt`](domains/03-advanced-traffic-mgmt) |
| 4 | Network Security and Policy | 25% | [`domains/04-network-security-policy`](domains/04-network-security-policy) |
| 5 | Observability | 15% | [`domains/05-observability`](domains/05-observability) |

Full competency list per domain: [`docs/exam-domains.md`](docs/exam-domains.md).

## Repository layout

```
ckne-labs/
├── kind-config.yaml            # 3-node Kind config, default CNI disabled
├── bootstrap.sh                 # Provision the cluster
├── reset-cluster.sh             # Tear down and clean up between attempts
├── docs/
│   ├── exam-domains.md          # Full official curriculum + weight per competency
│   └── resource-map.md          # Every doc link you supplied, mapped to a domain/scenario
├── domains/
│   ├── 01-core-infra-cni/
│   ├── 02-service-networking-dns/
│   ├── 03-advanced-traffic-mgmt/
│   ├── 04-network-security-policy/
│   └── 05-observability/
└── practice-exam/
    ├── PRACTICE_EXAM.md         # 20 scenario questions, weighted to match domain %
    └── ANSWERS.md
```

Each scenario folder follows the same four files:

- `task.md` — the objective, written as an exam-style prompt (no hand-holding)
- `setup.sh` — puts the cluster into the "broken"/starting state
- `solution.md` — the worked solution with commentary on *why*, not just *what*
- `verify.sh` — a script that checks your work programmatically, the same way the exam does

## Prerequisites

CKNE assumes CKA-level cluster administration. If `kubectl`, namespaces, Deployments, and Services aren't already second nature, do CKA-level prep first — this repo does not re-teach cluster administration.

Tooling used across labs: `kind`, `docker`, `kubectl`, `helm`, `cilium` CLI, `dig`/`nslookup`, `iptables`, `tcpdump`. Some Domain 3/5 labs (Cilium ClusterMesh, egress gateway, Hubble, LLM inference routing) assume Cilium as the CNI rather than the manual bridge config used in Domain 1 — each `setup.sh` says which CNI state it expects.

## Getting started

```bash
git clone <this-repo>
cd ckne-labs
./bootstrap.sh
cd domains/01-core-infra-cni/01-manual-cni-config
cat task.md
./setup.sh
# ... do the work ...
./verify.sh
cat solution.md   # only after you've attempted it
```

## A note on the "Advanced Traffic Management" domain

This is the newest and least-precedented domain — LLM-aware traffic routing (KV-cache locality, prefill/decode-aware scheduling) is a live area (KServe's `LLMInferenceService`, introduced in KServe v0.16, built on `llm-d` and the Gateway API Inference Extension's `InferencePool`). Where a lab touches this, `solution.md` calls out which parts are stable API and which parts are illustrative because the underlying projects are still moving quickly. Don't take exact field names in this domain as gospel — verify against upstream docs before the exam.

## Contributing

PRs welcome for new scenarios, corrections, or updated links as the CKNE curriculum matures out of beta. See `docs/exam-domains.md` for gaps you can fill.
