#!/usr/bin/env bash
set -uo pipefail
echo "This scenario spans two clusters — verify manually against both contexts:"
echo
echo "  cilium clustermesh status --context cluster1"
echo "  cilium clustermesh status --context cluster2"
echo "  cilium service list --context cluster1 | grep catalog-svc"
echo
echo "Confirm both clustermesh status calls report 'Ready' for the peer cluster, and"
echo "that the catalog-svc service map entry lists backends tagged with both cluster names."
