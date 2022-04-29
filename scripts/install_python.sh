#!/bin/bash
set -e

## build ARGs
NCPUS=${NCPUS:-1}
RETICULATE_MINICONDA_ENABLED=${RETICULATE_MINICONDA_ENABLED:-FALSE}

apt-get update && apt-get install -y --no-install-recommends \
	git \
	libpng-dev \
        libpython3-dev \
        python3-dev \
        python3-pip \
        python3-virtualenv \
        python3-venv \
        swig && \
    rm -rf /var/lib/apt/lists/*

python3 -m pip --no-cache-dir install --upgrade \
  pip \
  setuptools \
  virtualenv

# Some TF tools expect a "python" binary
if [ ! -e /usr/local/bin/python ]; then
  ln -s $(which python3) /usr/local/bin/python
fi

## Create a system-wide venv, but do not make it the default
VENV_PATH="/opt/venv"
mkdir -p ${VENV_PATH} 
python3 -m venv ${VENV_PATH}/reticulate
## Ensure RStudio inherits this env var
echo "" >> ${R_HOME}/etc/Renviron.site
echo "RETICULATE_MINICONDA_ENABLED=${RETICULATE_MINICONDA_ENABLED}" >> ${R_HOME}/etc/Renviron.site

## symlink these so that these are available when switching to a new venv
## -f check for file, -L for link, -e for either
if [ ! -e /usr/local/bin/python ]; then
  ln -s $(which python3) /usr/local/bin/python
fi

if [ ! -e /usr/local/bin/pip ]; then
  ln -s ${VENV_PATH}/bin/pip /usr/local/bin/pip
fi

if [ ! -e /usr/local/bin/virtualenv ]; then
  ln -s ${VENV_PATH}/bin/virtualenv /usr/local/bin/virtualenv
fi

 
install2.r --error --skipinstalled -n $NCPUS reticulate


## Enable pyenv
/rocker_scripts/install_pyenv.sh

# Clean up
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/downloaded_packages
