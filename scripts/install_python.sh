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

# Setup a virtualenv to install things into

# Put things under /opt/venv, if nothing else is specified
export VIRTUAL_ENV="${VIRTUAL_ENV:=/opt/venv}"
export PATH="${VIRTUAL_ENV}/bin:${PATH}"

# Make sure that Rstudio sees these env vars too
echo "PATH=${PATH}" >>"${R_HOME}/etc/Renviron.site"
echo "VIRTUAL_ENV=${VIRTUAL_ENV}" >>"${R_HOME}/etc/Renviron.site"

python3 -m venv "${VIRTUAL_ENV}"

# Upgrade version of pip inside the virtualenv
python3 -m pip --no-cache-dir install --upgrade \
    pip

# Make the venv owned by the staff group, so users can install packages
# without having to be root
chown -R root:staff "${VIRTUAL_ENV}"
chmod -R g+ws "${VIRTUAL_ENV}"

install2.r --error --skipmissing --skipinstalled -n "$NCPUS" reticulate

# Clean up
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/downloaded_packages

## Strip binary installed lybraries from RSPM
## https://github.com/rocker-org/rocker-versioned2/issues/340
strip /usr/local/lib/R/site-library/*/libs/*.so

## Don't use OpenBLAS with reticulate on Ubuntu 20.04
## https://github.com/rocker-org/rocker-versioned2/issues/471
source /etc/os-release
if [ "${UBUNTU_CODENAME}" == "focal" ]; then
    if R -q -e 'sessionInfo()' | grep -q openblas; then
        ARCH=$(uname -m)
        echo "Switching BLAS (Details: https://github.com/rocker-org/rocker-versioned2/issues/471)"
        update-alternatives --set "libblas.so.3-${ARCH}-linux-gnu" "/usr/lib/${ARCH}-linux-gnu/blas/libblas.so.3"
        update-alternatives --set "liblapack.so.3-${ARCH}-linux-gnu" "/usr/lib/${ARCH}-linux-gnu/lapack/liblapack.so.3"
    fi
fi

# Check that python and python3 point to correct places
echo "Check python, python3 and pip executables point to the correct place..."
echo "python -> $(which python)"
echo "python3 -> $(which python3)"
echo "pip -> $(which pip)"

# Check Python version
echo -e "Check the Python to use with reticulate...\n"

R -q -e 'reticulate::py_discover_config(required_module = NULL, use_environment = NULL)'

echo -e "\nInstall Python, done!"
