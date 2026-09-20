# Contributing

CKNE is in beta, and so is this repo — see the beta note in `README.md`. Useful contributions:

- New scenarios filling the gaps listed at the bottom of `docs/exam-domains.md`
- Reports of a `setup.sh`/`verify.sh` that didn't work as written on a real cluster, including which tool versions you hit it with — this repo hasn't been exhaustively run against every Cilium/Istio/cert-manager/KServe version combination, so these reports are genuinely useful, not just noise
- Corrections where upstream APIs (Gateway API, KServe/llm-d especially) have moved since a scenario was written
- Fixes to `verify.sh` scripts that give false positives/negatives on real clusters

Keep the four-file pattern (`task.md`, `setup.sh`, `solution.md`, `verify.sh`) for every new scenario, and place it under the correct `domains/0N-.../` directory matching its official competency, not a new top-level category.
