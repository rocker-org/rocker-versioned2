#!/bin/bash

set -e

## build ARGs
NCPUS=${NCPUS:--1}

apt-get update
apt-get -y --no-install-recommends install \
    libxml2-dev \
    libcairo2-dev \
    libgit2-dev \
    default-libmysqlclient-dev \
    libpq-dev \
    libsasl2-dev \
    libsqlite3-dev \
    libssh2-1-dev \
    libxtst6 \
    libcurl4-openssl-dev \
    unixodbc-dev
rm -rf /var/lib/apt/lists/*

install2.r --error --skipinstalled -n "$NCPUS" \
    tidyverse \
    devtools \
    rmarkdown \
    BiocManager \
    vroom \
    gert

## dplyr database backends
install2.r --error --skipmissing --skipinstalled -n "$NCPUS" \
    arrow \
    dbplyr \
    DBI \
    dtplyr \
    duckdb \
    nycflights13 \
    Lahman \
    RMariaDB \
    RPostgres \
    RSQLite \
    fst

## a bridge to far? -- brings in another 60 packages
# install2.r --error --skipinstalled -n "$NCPUS" tidymodels

rm -rf /tmp/downloaded_packages

# Check the tidyverse core packages' version
echo -e "Check the tidyverse package...\n"

R -q -e "library(tidyverse)"

echo -e "\nInstall tidyverse package, done!"
