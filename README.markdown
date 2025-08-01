# CNE Cookbook

## Purpose

This repository provides a set of Makefile-driven automation recipes for
deploying and testing cloud native Liferay DXP on a local Kubernetes cluster
using k3d. It consolidates common tasks such as cluster setup, deployment, and
cleanup, making it easier for developers to work with Liferay DXP in a
reproducible local k8s cluster environment.

## Key Features

- Scripts for creating and managing a local k3d Kubernetes cluster
- Makefile recipes for deploying Liferay DXP and client extensions
- Reusable ingredients files that makes it easy to compose different helm chart
  customizations
- Commands for cleaning up deployments and cluster resources

## Main Commands

Run these commands from the root of the repository using `make <target>`.

### Recipes

- `make cx-message-broker-poc` Deploys the "cx-message-broker-poc" recipe using
  the default DXP image. This recipe includes a message broker for CX
  applications demonstration that was created during the 2025 Exchange Program.

- `make cx-samples` Deploys the "cx-samples" recipe using the default DXP image.
  This recipe includes various client extension samples that demonstrates one of
  each different 'kind' of CX deployment.

- `make saas-testbed` Deploys the "saas-testbed" recipe using a specific SaaS
  DXP image.

### Cluster Management

- `make start-cluster` Creates and configures the k3d cluster, installs
  dependencies, and patches CoreDNS.

- `make create-cluster` Creates the k3d cluster if it does not exist.

- `make clean-cluster` Deletes the k3d cluster.

### Deployment

All of the following commands assume the cluster is running and the necessary
recipe variables are set. It will prompt for any missing variables.

- `make deploy` Deploys workspace, DXP, and client extensions to the cluster.

- `make deploy-workspace` Deploys Liferay modules to the local mount.

- `make deploy-dxp` Deploys the DXP image to the cluster.

- `make deploy-cx` Deploys client extensions to the cluster.

### Cleanup

- `make clean` Cleans up everything (cluster and data).

- `make clean-data` Deletes persistent volume claims in the cluster.

- `make clean-local-mount` Removes files from the local mount directory.

- `make clean-workspace` Cleans up the recipe workspace directory build files

### Undeploy

- `make undeploy` Removes both DXP and client extensions from the cluster.

- `make undeploy-dxp` Removes DXP deployment and related ConfigMaps.

- `make undeploy-cx` Removes client extensions and related ConfigMaps.

### Utilities

- `make help` Lists all available commands with descriptions.

- `make switch-context` Switches kubectl context to the k3d cluster.

- `make patch-coredns` Patches CoreDNS to resolve hostnames for the cluster.

- `make license` Extracts the license.xml from the DXP image.

## Getting Started

1. **Make sure you have all the installed prerequisites:**

1. **Clone the repository:**

   ```bash
   git clone <repo-url>
   cd cne-cookbook
   ```

1. **Start the cluster:**

   ```bash
   make start-cluster
   ```

1. **Deploy a recipe:**

   ```bash
   make cx-message-broker-poc
   # or
   make saas-testbed
   ```

1. Access the DXP instance in your browser at `http://main.dxp.localhost.me`

1. Access the default admin password for DXP by using the following command:

   ```bash
   kubectl get secrets liferay-default -o \
        jsonpath='{.data.LIFERAY_DEFAULT_PERIOD_ADMIN_PERIOD_PASSWORD}' \
        -n liferay-system | base64 -d && echo
   ```

## Installed Prerequisites

Ensure you have the following tools installed on your system:

- make (plus sed/grep basically any POSIX compliant shell)
- Docker
- k3d
- kubectl
- helm
- jq
- yq

## Contribution Notes

### Adding New Recipes

- Recipes are defined in the `recipes/` directory. Each recipe contains an
  ingredients file that points to other values files that are needed to
  customize the liferay chart deployment.
- Environment variables such as `RECIPE` and `DXP_IMAGE_TAG` are set and then
  `recipe` target is called.
- Also each recipe has an optional 'workspace/' folder that contains osgi
  modules that will be deployed to DXP or client extension projects that will be
  deployed to the cluster using provisional client-extension helm chart.

### Reusing Ingredients

- Ingredients are defined in the `ingredients/` directory. These are reusable
  values files that can be used across multiple recipes.
- Each ingredient file that contains `customXXX` values must use a key prefixed
  with `x-` This allows the Liferay helm chart to merge these values
  non-destructively with the default values provided by the chart.

### Deploying Client Extensions

- In order to deploy client extensions, you need to have a file next to the
  `client-extension.yaml` file named `cx.yaml_extra` In this file it will
  contain the fragment of values.yaml that are needed when deploying the Liferay
  helm chart for client extensions.
- See examples in the
  `cx-samples/workspace/client-extensions/**/cx.values_extra`
