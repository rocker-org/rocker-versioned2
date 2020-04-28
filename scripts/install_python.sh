#!/bin/bash
set -e

apt-get update && apt-get install -y --no-install-recommends \
        libpython3-dev \
        python3-dev \
        python3-pip \
        python3-virtualenv \
        python3-venv && \
    rm -rf /var/lib/apt/lists/*
python3 -m venv ${PYTHON_VENV_PATH}
pip3 install --no-cache-dir --upgrade pip
pip3 install --no-cache-dir virtualenv


install2.r --skipinstalled --error reticulate 

## Ensure RStudio inherits this env var
echo "\nWORKON_HOME=${WORKON_HOME}" >> ${R_HOME}/etc/Renviron



## symlink these so that these are available when switching to a new venv
ln -s ${PYTHON_VENV_PATH}/bin/pip /usr/local/bin/pip
ln -s ${PYTHON_VENV_PATH}/bin/virtualenv /usr/local/bin/virtualenv

## Allow staff-level users to modify the shared environment
chown -R :staff ${WORKON_HOME}
chmod g+wx ${WORKON_HOME}
chown :staff ${PYTHON_VENV_PATH}

