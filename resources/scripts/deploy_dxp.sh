#!/usr/bin/env bash

RECIPE=$1
DXP_IMAGE_TAG=$2

values_files=()

if [[ -f "${PWD}/recipes/${RECIPE}/ingredients.yaml" ]]; then
    while IFS= read -r ingredient; do
        values_files+=("-f" "${PWD}/ingredients/${ingredient}")
    done < <(yq -r ".ingredients[]" "${PWD}/recipes/${RECIPE}/ingredients.yaml")
fi

values_args=$(printf " %s" "${values_files[@]}")

helm upgrade -i liferay \
		oci://us-central1-docker.pkg.dev/liferay-artifact-registry/liferay-helm-chart/liferay-default \
       -f "${PWD}/recipes/${RECIPE}/values.yaml" \
		$values_args \
		--create-namespace \
		--namespace liferay-system \
		--set "image.tag=${DXP_IMAGE_TAG}" \
		--set-file "configmap.data.license\.xml=license.xml" \
		--timeout 10m \
		--wait

