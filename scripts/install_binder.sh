#!/bin/bash
set -e

RSTUDIO_VERSION=1.3.959 /rocker_scripts/install_rstudio.sh

## NOTE: this runs as user NB_USER!
PYTHON_VENV_PATH=${PYTHON_VENV_PATH:-/opt/venv/reticulate}
NB_USER=${NB_USER:-rstudio}
NB_UID=${NB_UID:-1000}
WORKDIR=${WORKDIR:-/home/${NB_USER}}
usermod -l ${NB_USER} rstudio
# Create a venv dir owned by unprivileged user & set up notebook in it
# This allows non-root to install python libraries if required
mkdir -p ${PYTHON_VENV_PATH} && chown -R ${NB_USER} ${PYTHON_VENV_PATH}

# And set ENV for R! It doesn't read from the environment...
echo "PATH=${PATH}" >> ${R_HOME}/etc/Renviron
echo "export PATH=${PATH}" >> ${WORKDIR}/.profile

## This gets run as user
su ${NB_USER}
cd ${WORKDIR}
python3 -m venv ${PYTHON_VENV_PATH}
pip3 install --no-cache-dir jupyter-rsession-proxy

R --quiet -e "devtools::install_github('IRkernel/IRkernel')"
R --quiet -e "IRkernel::installspec(prefix='${PYTHON_VENV_PATH}')"
