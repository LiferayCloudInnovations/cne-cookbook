#!/usr/bin/env bash

## check if recipe vars are set and throw error otherwise

if [ -z "${RECIPE}" ]; then
  echo "Error: RECIPE is not set. Please set it before running the script. export RECIPE=name-of-folder"
  exit 1
else
  echo "RECIPE is set to '${RECIPE}'."
fi
