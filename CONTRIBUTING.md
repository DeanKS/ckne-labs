# Contributing

CKNE is in beta, so the curriculum, task wording, and tooling may shift before GA. Useful contributions:

- New scenarios filling the gaps listed at the bottom of `docs/exam-domains.md`
- Corrections where upstream APIs (Gateway API, KServe/llm-d especially) have moved since a scenario was written
- Fixes to `verify.sh` scripts that give false positives/negatives on real clusters

Keep the four-file pattern (`task.md`, `setup.sh`, `solution.md`, `verify.sh`) for every new scenario, and place it under the correct `domains/0N-.../` directory matching its official competency, not a new top-level category.
