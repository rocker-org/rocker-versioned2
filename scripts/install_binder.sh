#!/bin/sh

## NOTE: this runs as user NB_USER!


python3 -m venv ${VENV_DIR}
# Explicitly install a new enough version of pip
pip3 install pip==9.0.1
pip3 install --no-cache-dir jupyter-rsession-proxy

R --quiet -e "devtools::install_github('IRkernel/IRkernel')"
R --quiet -e "IRkernel::installspec(prefix='${VENV_DIR}')"



