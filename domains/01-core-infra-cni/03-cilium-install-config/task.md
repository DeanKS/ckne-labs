# Scenario: Installing Cilium via the Cilium CLI and Mapping to Helm Values

**Domain:** Core Infrastructure and CNI (15%)
**Competencies:** Installing and Configuring CNI Plugins

## Why this scenario exists

Real-world CKNE beta feedback (`docs/exam-strategy.md`) singles this out specifically: "focus on Cilium installation with the Cilium CLI and how CLI options map to Helm values." Scenario 01 in this domain deliberately teaches raw CNI mechanics with nothing installed — a different, foundational skill. This scenario is the Cilium-specific one the beta report says actually gets tested.

## Context

A fresh Kind cluster (`disableDefaultCNI: true`, same as `kind-config.yaml`) has no CNI installed. A colleague has handed you a broken install they attempted:

```bash
cilium install \
  --set kubeProxyReplacement=false \
  --set hubble.enabled=false
```

Nodes are stuck `NotReady` and Hubble tooling in later scenarios of this repo won't work against this install.

## Task

1. Install Cilium using the **Cilium CLI**, with `kubeProxyReplacement` enabled and Hubble (plus its UI) enabled.
2. Without re-running `cilium install` from scratch, identify the exact Helm values your CLI flags correspond to — the CLI is a thin wrapper around a Helm chart, and being able to translate between the two is the actual skill being tested here, not just running one command.
3. Confirm the cluster is fully healthy: nodes `Ready`, `kube-proxy` no longer doing the work it used to (or absent entirely, if this is a fresh cluster), Hubble relay and UI both up.

## Success criteria

- `cilium status` reports `OK` with no warnings.
- `cilium config view | grep kube-proxy-replacement` (or `cilium status --verbose`) shows kube-proxy replacement active.
- `helm get values cilium -n kube-system` shows the Helm-level equivalents of the CLI flags you used.
- `hubble ui` (or `cilium hubble ui`) opens successfully.

## Official documentation

- Cilium CLI install reference — https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/
- Cilium Helm reference — https://docs.cilium.io/en/stable/helm-reference/
