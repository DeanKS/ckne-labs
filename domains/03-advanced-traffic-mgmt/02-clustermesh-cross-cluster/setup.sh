#!/usr/bin/env bash
set -euo pipefail
echo "This lab assumes two separate Kind clusters already exist: cluster1 and cluster2,"
echo "both with Cilium installed as CNI, each with a local 'catalog-svc' Service/Deployment."
echo "Set contexts before starting: kubectl config get-contexts"
echo
echo "Reminder: ClusterMesh requires unique --cluster-id and --cluster-name per cluster,"
echo "and is mutually exclusive with the egress gateway feature on the same datapath."
