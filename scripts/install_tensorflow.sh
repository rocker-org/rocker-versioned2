#!/bin/sh
set -e

R -e "install.packages('keras')"
R -e "tensorflow::install_tensorflow(); keras::install_keras()"
R -e "install.packages('remotes'); remotes::install_github('greta-dev/greta')"

