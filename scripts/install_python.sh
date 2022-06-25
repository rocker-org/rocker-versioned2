#!/bin/bash
set -e

## build ARGs
NCPUS=${NCPUS:--1}

# a function to install apt packages only if they are not installed
function apt_install() {
    if ! dpkg -s "$@" >/dev/null 2>&1; then
        if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
            apt-get update
        fi
        apt-get install -y --no-install-recommends "$@"
    fi
}

apt_install \
    libpng-dev \
    libpython3-dev \
    python3-dev \
    python3-pip \
    python3-venv \
    swig

python3 -m pip --no-cache-dir install --upgrade \
    pip

# Some TF tools expect a "python" binary
if [ ! -e /usr/local/bin/python ]; then
    ln -s "$(which python3)" /usr/local/bin/python
fi

install2.r --error --skipmissing --skipinstalled -n "$NCPUS" reticulate

# Clean up
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/downloaded_packages

## Strip binary installed lybraries from RSPM
## https://github.com/rocker-org/rocker-versioned2/issues/340
strip /usr/local/lib/R/site-library/*/libs/*.so
