#!/bin/sh
set -e

apt-get update && apt-get install -y --no-install-recommends \
        libpython3-dev \
        python3-dev \
        python3-pip \
        python3-venv && \
    rm -rf /var/lib/apt/lists/*
python3 -m venv ${PYTHON_VENV_PATH}
pip3 install --no-cache-dir --upgrade pip
pip3 install --no-cache-dir virtualenv

## Ensure RStudio inherits this env var
echo "\nRETICULATE_PYTHON_ENV=${RETICULATE_PYTHON_ENV}" >> ${R_HOME}/etc/Renviron

## symlink these because reticulate hardwires these PATHs...
ln -s ${PYTHON_VENV_PATH}/bin/pip /usr/local/bin/pip
ln -s ${PYTHON_VENV_PATH}/bin/virtualenv /usr/local/bin/virtualenv

chown :staff ${PYTHON_VENV_PATH}

