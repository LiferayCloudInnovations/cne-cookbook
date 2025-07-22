#!/usr/bin/env bash

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
git_root="$(git -C "$script_dir" rev-parse --show-toplevel)"
cluster_name=${1}

gateway_ip=$(k3d cluster list "${cluster_name}" -o json | jq -r '[.[] | .nodes[] | select(.runtimeLabels["k3d.server.loadbalancer"] == "k3d-'"${cluster_name}"'-serverlb")][0] | .IP["IP"]')

sed "s/__GATEWAY_IP__/$gateway_ip/" "${git_root}/resources/manifests/coredns-custom.yaml" | kubectl apply -f -
