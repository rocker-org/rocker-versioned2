#!/bin/bash

# always set this for scripts but don't declare as ENV..
export DEBIAN_FRONTEND=noninteractive


# a function to install apt packages only if they are not installed
function apt_install() {
    if ! dpkg -s "$@" >/dev/null 2>&1; then
        if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
            apt-get -qq update
        fi
        apt-get install -y --no-install-recommends "$@"
    fi
}

apt_install pciutils

python3 -m pip install --no-cache-dir torch tensorflow[and-cuda] keras

install2.r --error --skipmissing --skipinstalled torch tensorflow keras 

# Clean up
rm -rf /var/lib/apt/lists/*
rm -r /tmp/downloaded_packages


