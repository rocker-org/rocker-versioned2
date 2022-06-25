#!/bin/bash
set -e

## build ARGs
NCPUS=${NCPUS:-"-1"}

NB_USER=${NB_USER:-${DEFAULT_USER:-"rstudio"}}

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
    sudo \
    libzmq3-dev

# set up the default user if it does not exist
if ! id -u "${NB_USER}" >/dev/null 2>&1; then
    /rocker_scripts/default_user.sh "${NB_USER}"
fi

# install python
/rocker_scripts/install_python.sh

python3 -m pip install --no-cache-dir jupyter-rsession-proxy notebook jupyterlab

install2.r --error --skipmissing --skipinstalled -n "$NCPUS" remotes

R --quiet -e 'remotes::install_github("IRkernel/IRkernel@*release")'
R --quiet -e 'IRkernel::installspec(user = FALSE)'

# Clean up
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/downloaded_packages
