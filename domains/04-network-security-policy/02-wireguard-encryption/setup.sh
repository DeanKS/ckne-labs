#!/usr/bin/env bash
set -euo pipefail
echo "Assumes Cilium is already installed as the CNI without encryption enabled."
cilium status 2>/dev/null | grep -i encryption || echo "Encryption not yet configured."
