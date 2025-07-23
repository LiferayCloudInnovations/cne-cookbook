#!/usr/bin/env bash

## check if recipe vars are set and throw error otherwise

if [ -z "${RECIPE}" ]; then
  echo "Error: RECIPE is not set. Please set it before running the script. export RECIPE=name-of-folder"
  exit 1
else
  echo "RECIPE is set to '${RECIPE}'."
fi

if [ -z "${DXP_IMAGE_TAG}" ]; then
  echo "Error: DXP_IMAGE_TAG is not set. Please set it before running the script. export DXP_IMAGE_TAG=2025.q2.1"
  exit 1
else
  echo "DXP_IMAGE_TAG is set to '${DXP_IMAGE_TAG}'."
fi
