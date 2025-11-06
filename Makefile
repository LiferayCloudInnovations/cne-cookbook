.ONESHELL:
SHELL = bash

.DEFAULT_GOAL = help
CLUSTER_NAME := cne
DOMAIN_SUFFIX := localtest.me
LOCAL_MOUNT := tmp/mnt/local

### RECIPES ###

cx-direct-deploy-test: ## Test direct deploy cx
	export RECIPE="cx-direct-deploy-test"
	$(MAKE) recipe

cx-manualmode-multiple-virtual-instances:
	export RECIPE="cx-manualmode-multiple-virtual-instances"
	$(MAKE) recipe

cx-message-broker-poc: ## Client Extensions with Message Broker POC
	export RECIPE="cx-message-broker-poc"
	$(MAKE) recipe

cx-samples: ## Client Extensions Samples
	export RECIPE="cx-samples"
	$(MAKE) recipe

lpd65526-better-batch-errors:
	export RECIPE="lpd65526-better-batch-errors"
	$(MAKE) recipe

override-agent-test:
	export RECIPE="override-agent-test"
	$(MAKE) recipe

saas-bad-configmap: ## SaaS Bad Configmap
	export RECIPE="saas-bad-configmap"
	$(MAKE) recipe

saas-testbed: ## SaaS Testbed
	export RECIPE="saas-testbed"
	$(MAKE) recipe

multiple-object-entry-managers-with-same-name:
	export RECIPE="multiple-object-entry-managers-with-same-name"
	$(MAKE) recipe

### TARGETS ###

check-recipe-vars: ## Check if recipe variables are set, throw error otherwise
	@./resources/scripts/check_recipe_vars.sh

clean: clean-local-mount ## Clean up everything
	@k3d cluster delete "${CLUSTER_NAME}" || true

clean-data: switch-context undeploy-dxp ## Clean up data in the cluster
	@kubectl delete pvc --selector "app.kubernetes.io/name=liferay-default" -n liferay-system

clean-local-mount: ## Clean local mount
	@rm -rf "${PWD}/${LOCAL_MOUNT}"/*

clean-workspace: check-recipe-vars ## Clean recipe workspace
	@cd "${PWD}/recipes/${RECIPE}/workspace" && ./gradlew clean
	@rm -rf "${PWD}/recipes/${RECIPE}/workspace/bundles"

copy-password:
	@kubectl -n liferay-system get secret liferay-default -o jsonpath="{.data.LIFERAY_DEFAULT_PERIOD_ADMIN_PERIOD_PASSWORD}" | base64 -d | wl-copy

create-cluster: mkdir-local-mount ## Start k3d cluster
	@k3d cluster list "${CLUSTER_NAME}" ||
		k3d cluster create "${CLUSTER_NAME}" \
			--port 80:80@loadbalancer \
			--registry-create registry:5000 \
			--volume "${PWD}/${LOCAL_MOUNT}:/mnt/local@all:*"

deploy: deploy-workspace deploy-dxp deploy-cx

deploy-cx: check-recipe-vars switch-context ## Deploy Client extensions to cluster
	@(stat "${PWD}/recipes/${RECIPE}/workspace/client-extensions" && cd "${PWD}/recipes/${RECIPE}/workspace" && ./gradlew helmDeploy -x test -x check) || true

deploy-dxp: check-recipe-vars deploy-workspace start-cluster switch-context license
	@./resources/scripts/deploy_dxp.sh ${RECIPE}

deploy-workspace: check-recipe-vars clean-local-mount mkdir-local-mount ## Deploy Liferay modules to local mount
	@(stat "${PWD}/recipes/${RECIPE}/workspace" && cd "${PWD}/recipes/${RECIPE}/workspace" && ./gradlew -Pliferay.workspace.home.dir="${PWD}/${LOCAL_MOUNT}" deploy -x test -x check) || true

help:
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

install-ksgate: switch-context create-cluster
	@helm upgrade -i ksgate \
		oci://ghcr.io/ksgate/charts/ksgate \
		--create-namespace \
		--namespace ksgate-system \
		--timeout 5m \
		--wait

license: ## Extract license.xml from DXP image
	@./resources/scripts/extract_license.sh

mkdir-local-mount: ## Create k3d local mount folder
	@mkdir -p "${PWD}/${LOCAL_MOUNT}"


patch-coredns: switch-context ## Patch CoreDNS to resolve hostnames
	@./resources/scripts/patch_coredns.sh ${CLUSTER_NAME} ${DOMAIN_SUFFIX}
	@kubectl rollout restart deployment coredns -n kube-system

recipe: start-cluster deploy-workspace deploy-dxp deploy-cx ## Make a recipe (can't be called directly without setting RECIPE var)

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
