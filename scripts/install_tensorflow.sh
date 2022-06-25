#!/bin/bash
set -e

## build ARGs
NCPUS=${NCPUS:--1}

## Install python dependency
/rocker_scripts/install_python.sh

install2.r --error --skipinstalled -n "$NCPUS" keras

rm -r /tmp/downloaded_packages

## Strip binary installed lybraries from RSPM
## https://github.com/rocker-org/rocker-versioned2/issues/340
strip /usr/local/lib/R/site-library/*/libs/*.so
