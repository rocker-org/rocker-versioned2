#!/bin/bash
set -e

NB_USER=${NB_USER:-${DEFAULT_USER:-"rstudio"}}

# set up the default user if it does not exist
if ! id -u "${NB_USER}" >/dev/null 2>&1; then
    /rocker_scripts/default_user.sh "${NB_USER}"
fi

PYTHON_VENV_PATH=${PYTHON_VENV_PATH:-/opt/venv/reticulate}
WORKDIR=${WORKDIR:-/home/${NB_USER}}
# Create a venv dir owned by unprivileged user & set up notebook in it
# This allows non-root to install python libraries if required
mkdir -p "${PYTHON_VENV_PATH}"
chown -R "${NB_USER}" "${PYTHON_VENV_PATH}"

PATH=/opt/pyenv/bin:${PATH}

# And set ENV for R! It doesn't read from the environment...
echo "PATH=${PATH}" >>"${R_HOME}/etc/Renviron.site"
echo "export PATH=${PATH}" >>"${WORKDIR}/.profile"

cd "${WORKDIR}"
## This gets run as user
sudo -u "${NB_USER}" python3 -m venv "${PYTHON_VENV_PATH}"
pip3 install --no-cache-dir jupyter-rsession-proxy notebook jupyterlab >=2.0

R --quiet -e "devtools::install_github('IRkernel/IRkernel')"
R --quiet -e "IRkernel::installspec(prefix='${PYTHON_VENV_PATH}')"
