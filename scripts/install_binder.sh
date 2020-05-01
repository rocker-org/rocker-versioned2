#!/bin/sh

## NOTE: this runs as user NB_USER!


python3 -m venv ${PYTHON_VENV_PATH}
# Explicitly install a new enough version of pip
pip3 install pip==9.0.1
pip3 install --no-cache-dir jupyter-rsession-proxy

R --quiet -e "devtools::install_github('IRkernel/IRkernel')"
R --quiet -e "IRkernel::installspec(prefix='${PYTHON_VENV_PATH}')"


