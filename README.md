# CKNE Labs

Hands-on lab repository for the [Certified Kubernetes Network Engineer (CKNE)](https://training.linuxfoundation.org/certification/certified-kubernetes-network-engineer-ckne/) exam, structured the same way as community repos for CKA/CKAD/CKS (setup → task → solution → verify), but organized around CKNE's actual five domains and weights.

> **CKNE is currently in beta** (as of writing: online, proctored, performance-based, 2 hours, $99 beta price, one free retake). Domain weights and task wording can still change before general availability - check the [official page](https://training.linuxfoundation.org/certification/certified-kubernetes-network-engineer-ckne/) before you sit the exam.

> **This repo is also in beta.** Just like the exam it's built for, treat these labs as a work in progress rather than a finished, exhaustively-tested product. Concretely: not every `setup.sh`/`verify.sh` has been run end-to-end against a live cluster for every tool combination (Cilium version, Istio version, cert-manager version, etc.) - some are reasoned-through and syntax-checked rather than fully battle-tested. If something doesn't work as written, that's expected occasionally at this stage: check `docs/exam-domains.md` for known gaps, open an issue/PR with what you found (see `CONTRIBUTING.md`), and don't assume a stuck step is necessarily something you did wrong.

## Domain weighting (official)

| # | Domain | Weight | Directory |
|---|---|---|---|
| 1 | Core Infrastructure and CNI | 15% | [`domains/01-core-infra-cni`](domains/01-core-infra-cni) |
| 2 | Service Networking and DNS | 25% | [`domains/02-service-networking-dns`](domains/02-service-networking-dns) |
| 3 | Advanced Traffic Management | 20% | [`domains/03-advanced-traffic-mgmt`](domains/03-advanced-traffic-mgmt) |
| 4 | Network Security and Policy | 25% | [`domains/04-network-security-policy`](domains/04-network-security-policy) |
| 5 | Observability | 15% | [`domains/05-observability`](domains/05-observability) |

Full competency list per domain: [`docs/exam-domains.md`](docs/exam-domains.md). Real beta-exam feedback and how it shaped this repo: [`docs/exam-strategy.md`](docs/exam-strategy.md). Unvetted third-party courses/labs worth a look but not built into this repo: [`docs/further-study.md`](docs/further-study.md).

## Repository layout

```
ckne-labs/
├── kind-config.yaml            # 3-node Kind config, default CNI disabled
├── bootstrap.sh                 # Provision the cluster
├── reset-cluster.sh             # Tear down and clean up between attempts
├── docs/
│   ├── exam-domains.md          # Full official curriculum + weight per competency
│   ├── exam-strategy.md         # Notes from a real beta-exam sitter's write-up
│   ├── further-study.md         # Unvetted third-party courses/labs, kept separate from the resource map
│   └── resource-map.md          # Official docs + Cilium's own labs, mapped to a domain/scenario
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

- `task.md` - the objective, written as an exam-style prompt (no hand-holding)
- `setup.sh` - puts the cluster into the "broken"/starting state
- `solution.md` - the worked solution with commentary on *why*, not just *what*
- `verify.sh` - a script that checks your work programmatically, the same way the exam does

## Prerequisites

CKNE assumes CKA-level cluster administration. If `kubectl`, namespaces, Deployments, and Services aren't already second nature, do CKA-level prep first - this repo does not re-teach cluster administration.

### Required tooling

| Tool | Used for | Check it's ready |
|---|---|---|
| Docker Desktop (or Podman) | Container runtime backing every Kind node | `docker info` returns cluster/version data with no error |
| [`kind`](https://kind.sigs.k8s.io/) | Local Kubernetes clusters | `kind version` |
| `kubectl` | Talking to the cluster | `kubectl version --client` |
| `helm` | Installing Cilium and other charts | `helm version` |
| [`cilium` CLI](https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/#install-the-cilium-cli) | Enabling/checking Cilium features, ClusterMesh, status | `cilium version` |
| `dig` / `nslookup` | DNS scenarios (Domain 2) | usually pre-installed on macOS/Linux; on Windows use WSL |
| `git` | Cloning this repo and pushing your own fork | `git --version` |

Optional but used in specific scenarios: `jq` (Domain 5 flow-log filtering), `openssl` (Domain 4 TLS scenario - generating a self-signed cert for the lab).

**Docker/Podman must be running, not just installed** - `docker info` needs to succeed before `./bootstrap.sh` will work. On macOS/Windows this means the Docker Desktop app is actually open (`open -a Docker`, then wait for the whale icon to settle); on Linux it means the daemon service is started (`sudo systemctl start docker`). If you're on a managed/locked-down laptop and can't run Docker Desktop, `kind` also supports Podman as a drop-in: `export KIND_EXPERIMENTAL_PROVIDER=podman` before running `bootstrap.sh`.

If `docker`/`kind`/etc. are installed but your shell says `command not found`, it's almost always a PATH issue rather than a missing install - confirm with `which docker` (or the relevant tool) and check the binary's actual location is on your `$PATH`, and remember to open a **new** terminal tab after any PATH change.

### Required access

- A GitHub account with either an SSH key registered (recommended: `ssh -T git@github.com` should greet you by username) or a Personal Access Token with `repo` scope, if you intend to push this repo or your own fork rather than just running it locally.
- No cloud account (AWS/Azure/etc.) is required - every lab runs entirely on local Kind clusters.

Tooling used across labs: `kind`, `docker`, `kubectl`, `helm`, `cilium` CLI, `dig`/`nslookup`, `iptables`, `tcpdump`. Some Domain 3/5 labs (Cilium ClusterMesh, egress gateway, Hubble, LLM inference routing) assume Cilium as the CNI rather than the manual bridge config used in Domain 1 - each `setup.sh` says which CNI state it expects.

**Note found through live testing:** Kind's node image only ships a minimal default set of CNI plugin binaries (`host-local`, `loopback`, `portmap`, `ptp`) - it does **not** include `bridge` or `tuning`, which Domain 1's manual-CNI scenarios need. Those scenarios' `setup.sh` now installs the missing binaries automatically (detecting node architecture and pulling the matching release from `containernetworking/plugins`), so this shouldn't surface as a blocker - but if you ever see a node stuck `NotReady` with a kubelet log saying `failed to find plugin "X" in path [/opt/cni/bin]`, this is almost always why, regardless of which scenario you're in.

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

This is the newest and least-precedented domain - LLM-aware traffic routing (KV-cache locality, prefill/decode-aware scheduling) is a live area (KServe's `LLMInferenceService`, introduced in KServe v0.16, built on `llm-d` and the Gateway API Inference Extension's `InferencePool`). Where a lab touches this, `solution.md` calls out which parts are stable API and which parts are illustrative because the underlying projects are still moving quickly. Don't take exact field names in this domain as gospel - verify against upstream docs before the exam.

## Contributing

PRs welcome for new scenarios, corrections, or updated links as the CKNE curriculum matures out of beta. See `docs/exam-domains.md` for gaps you can fill.
