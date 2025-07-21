.ONESHELL:
SHELL = bash

.DEFAULT_GOAL = help
CLUSTER_NAME := cne
DXP_IMAGE_TAG := 7.4.13-u132
LOCAL_MOUNT := tmp/mnt/local

### RECIPES ###

cx-direct-deploy-test: ## Test direct deploy cx
	export RECIPE="cx-direct-deploy-test"
	$(MAKE) recipe

cx-message-broker-poc: ## Client Extensions with Message Broker POC
	export RECIPE="cx-message-broker-poc"
	$(MAKE) recipe

### TARGETS ###

check-recipe-var: ## Check if RECIPE variable is set, throw error otherwise
	@./scripts/check_recipe_var

clean: clean-cluster ## Clean up everything

clean-cluster: ## Delete k3d cluster
	@k3d cluster delete "${CLUSTER_NAME}" || true

clean-data: switch-context undeploy-dxp ## Clean up data in the cluster
	@kubectl delete pvc --selector "app.kubernetes.io/name=liferay-default" -n liferay-system

clean-local-mount: ## Clean local mount
	@rm -rf "${PWD}/${LOCAL_MOUNT}"/*

deploy: deploy-workspace deploy-cx deploy-dxp

deploy-cx: check-recipe-var switch-context ## Deploy Client extensions to cluster
	@cd "${PWD}/recipes/${RECIPE}/workspace" && (./gradlew :client-extensions:helmDeploy -x test -x check || true)

deploy-dxp: check-recipe-var deploy-workspace switch-context license
	@helm upgrade -i liferay \
		oci://us-central1-docker.pkg.dev/liferay-artifact-registry/liferay-helm-chart/liferay-default \
		-f "${PWD}/recipe/${RECIPE}/values.yaml" \
		--create-namespace \
		--namespace liferay-system \
		--set "image.tag=${DXP_IMAGE_TAG}" \
		--set-file "configmap.data.license\.xml=license.xml" \
		--timeout 10m \
		--wait

deploy-workspace: check-recipe-var clean-local-mount ## Deploy Liferay modules to local mount
	@cd "${PWD}/recipe/${RECIPE}/workspace" && ./gradlew -Pliferay.workspace.home.dir="${PWD}/${LOCAL_MOUNT}" deploy -x test -x check

help:
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

license: ## Extract license.xml from DXP image
	@./scripts/extract_license

mkdir-local-mount: ## Create k3d local mount folder
	@mkdir -p "${PWD}/${LOCAL_MOUNT}"

recipe: start-cluster deploy-workspace deploy-dxp deploy-cx ## Make a recipe (can't be called directly without setting RECIPE var)

patch-coredns: switch-context ## Patch CoreDNS to resolve hostnames
	@./scripts/patch_coredns ${CLUSTER_NAME}
	@kubectl rollout restart deployment coredns -n kube-system

create-cluster: mkdir-local-mount ## Start k3d cluster
	@k3d cluster list "${CLUSTER_NAME}" ||
		k3d cluster create "${CLUSTER_NAME}" \
			--port 80:80@loadbalancer \
			--registry-create registry:5000 \
			--volume "${PWD}/${LOCAL_MOUNT}:/mnt/local@all:*"

install-ksgate: create-cluster
	@helm upgrade -i ksgate \
		oci://ghcr.io/ksgate/charts/ksgate \
		--create-namespace \
		--namespace ksgate-system \
		--timeout 5m \
		--wait

start-cluster: mkdir-local-mount create-cluster install-ksgate patch-coredns

switch-context: ## Switch kubectl context to k3d cluster
	@kubectx k3d-${CLUSTER_NAME}

undeploy: undeploy-cx undeploy-dxp

undeploy-cx: switch-context ## Clean up Client Extensions
	@helm list -n liferay-system -q --filter "-cx" | xargs -r helm uninstall -n liferay-system
	@kubectl -n liferay-system delete cm --selector "lxc.liferay.com/metadataType=ext-init"

undeploy-dxp: switch-context ## Clean up DXP deployment
	@helm list -n liferay-system -q --filter "liferay" | xargs -r helm uninstall -n liferay-system
	@kubectl -n liferay-system delete cm --selector "lxc.liferay.com/metadataType=dxp"
