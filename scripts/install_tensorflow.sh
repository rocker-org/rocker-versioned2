#!/bin/sh
set -e

TENSORFLOW_VERSION=${1:-${TENSORFLOW_VERSION:-default}}
KERAS_VERSION=${2:-${KERAS_VERSION:-default}}

install2.r --error --skipinstalled keras
Rscript -e "keras::install_keras(version = \"$KERAS_VERSION\", tensorflow = \"$TENSORFLOW_VERSION\")"

