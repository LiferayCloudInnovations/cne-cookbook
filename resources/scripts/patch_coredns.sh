#!/usr/bin/env bash

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
git_root="$(git -C "$script_dir" rev-parse --show-toplevel)"
cluster_name=${1}
domain_suffix=${2}

gateway_ip=$(k3d cluster list "${cluster_name}" -o json | jq -r '[.[] | .nodes[] | select(.runtimeLabels["k3d.server.loadbalancer"] == "k3d-'"${cluster_name}"'-serverlb")][0] | .IP["IP"]')

cat "${git_root}/resources/manifests/coredns-custom.yaml" | sed "s/__GATEWAY_IP__/${gateway_ip}/" | sed "s/__DOMAIN_SUFFIX__/${domain_suffix}/" | kubectl apply -f -
