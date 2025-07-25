.ONESHELL:
SHELL = bash

.DEFAULT_GOAL = help
CLUSTER_NAME := cne
DOMAIN_SUFFIX := localtest.me
DXP_IMAGE_TAG_DEFAULT := 2025.q1.15-lts
LOCAL_MOUNT := tmp/mnt/local

### RECIPES ###

cx-direct-deploy-test: ## Test direct deploy cx
	export RECIPE="cx-direct-deploy-test"
	export DXP_IMAGE_TAG="${DXP_IMAGE_TAG_DEFAULT}"
	$(MAKE) recipe

cx-message-broker-poc: ## Client Extensions with Message Broker POC
	export RECIPE="cx-message-broker-poc"
	export DXP_IMAGE_TAG="${DXP_IMAGE_TAG_DEFAULT}"
	$(MAKE) recipe

cx-samples: ## Client Extensions Samples
	export RECIPE="cx-samples"
	export DXP_IMAGE_TAG="${DXP_IMAGE_TAG_DEFAULT}"
	$(MAKE) recipe

saas-testbed: ## SaaS Testbed
	export RECIPE="saas-testbed"
	export DXP_IMAGE_TAG="${DXP_IMAGE_TAG_DEFAULT}"
	$(MAKE) recipe

### TARGETS ###

check-recipe-vars: ## Check if recipe variables are set, throw error otherwise
	@./resources/scripts/check_recipe_vars.sh

clean: clean-cluster ## Clean up everything

clean-cluster: ## Delete k3d cluster
	@k3d cluster delete "${CLUSTER_NAME}" || true

clean-data: switch-context undeploy-dxp ## Clean up data in the cluster
	@kubectl delete pvc --selector "app.kubernetes.io/name=liferay-default" -n liferay-system

clean-local-mount: ## Clean local mount
	@rm -rf "${PWD}/${LOCAL_MOUNT}"/*

clean-workspace: check-recipe-vars ## Clean recipe workspace
	@cd "${PWD}/recipes/${RECIPE}/workspace" && ./gradlew clean

deploy: deploy-workspace deploy-dxp deploy-cx

deploy-cx: check-recipe-vars switch-context ## Deploy Client extensions to cluster
	@cd "${PWD}/recipes/${RECIPE}/workspace" && (./gradlew helmDeploy -x test -x check || true)

deploy-dxp: check-recipe-vars deploy-workspace switch-context license
	@./resources/scripts/deploy_dxp.sh ${RECIPE} ${DXP_IMAGE_TAG}

deploy-workspace: check-recipe-vars clean-local-mount ## Deploy Liferay modules to local mount
	@cd "${PWD}/recipes/${RECIPE}/workspace" && ./gradlew -Pliferay.workspace.home.dir="${PWD}/${LOCAL_MOUNT}" deploy -x test -x check

help:
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

license: ## Extract license.xml from DXP image
	@./resources/scripts/extract_license.sh

mkdir-local-mount: ## Create k3d local mount folder
	@mkdir -p "${PWD}/${LOCAL_MOUNT}"

recipe: start-cluster deploy-workspace deploy-dxp deploy-cx ## Make a recipe (can't be called directly without setting RECIPE var)

patch-coredns: switch-context ## Patch CoreDNS to resolve hostnames
	@./resources/scripts/patch_coredns.sh ${CLUSTER_NAME} ${DOMAIN_SUFFIX}
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
	@helm list -n liferay-system -q --filter "-cx" | xargs -r helm uninstall -n liferay-system --wait
	@kubectl -n liferay-system delete cm --selector "lxc.liferay.com/metadataType=ext-init"

undeploy-dxp: switch-context ## Clean up DXP deployment
	@helm list -n liferay-system -q --filter "liferay" | xargs -r helm uninstall -n liferay-system --wait
	@kubectl -n liferay-system delete cm --selector "lxc.liferay.com/metadataType=dxp"
