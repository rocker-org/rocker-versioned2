#!/bin/bash

## Usage: test.sh <script name> <script arg>
##
## For example, `/test.sh install_rstudio.sh latest` means
## run `/rocker_scripts/install_rstudio.sh latest`.
##
## A special arg `skip` to skip running the script.
## A special arg `none` to run the script with no args.

set -e

SCRIPT_NAME=${1:-"install_rstudio.sh"}
SCRIPT_ARG=${2:-"skip"}

SCRIPT_PATH="/rocker_scripts/${SCRIPT_NAME}"

if [ "$SCRIPT_ARG" = "skip" ]; then
    echo "Skip running ${SCRIPT_NAME}"
    exit 0
fi

echo "Test ${SCRIPT_NAME} with arg ${SCRIPT_ARG}"

if [ "$SCRIPT_ARG" = "none" ]; then
    SCRIPT_ARG=
fi

"$SCRIPT_PATH" "$SCRIPT_ARG"

echo "${SCRIPT_NAME} done!"
