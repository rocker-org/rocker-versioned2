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

# Install system dependencies needed for pharmaverse packages
apt_install \
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
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    unixodbc-dev \
    xz-utils \
    libfontconfig1-dev \
    libgdal-dev \
    libgeos-dev \
    libproj-dev \
    libsodium-dev

# Install tidyverse packages first (pharmaverse builds on tidyverse)
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

# Install core pharmaverse packages
install2.r --error --skipinstalled -n "$NCPUS" \
    admiral \
    admiralmetabolic \
    admiralneuro \
    admiralonco \
    admiralophtha \
    admiralpeds \
    admiralvaccine \
    cards \
    cardx \
    chevron \
    clinify \
    connector \
    covtracer \
    datacutr \
    datasetjson \
    diffdf \
    ggsurvfit \
    gridify \
    gtsummary \
    logrx \
    metacore \
    metatools \
    pharmaRTF \
    pharmaverseadam \
    pharmaverseraw \
    pharmaversesdtm \
    pkglite \
    rhino \
    riskmetric \
    rlistings \
    rtables \
    sdtmchecks \
    teal \
    teal.modules.general \
    teal.modules.clinical \
    tern \
    tfrmt \
    tfrmtbuilder \
    tidyCDISC \
    tidytlg \
    Tplyr \
    whirl \
    xportr

# Clean up
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/downloaded_packages

## Strip binary installed libraries from RSPM
## https://github.com/rocker-org/rocker-versioned2/issues/340
strip /usr/local/lib/R/site-library/*/libs/*.so

# Check that key tidyverse and pharmaverse packages are installed
echo -e "Check the tidyverse and pharmaverse packages...\n"

R -q -e "
# Check tidyverse installation
if(requireNamespace('tidyverse', quietly = TRUE)) {
  cat('✓ tidyverse installed successfully\n')
  library(tidyverse)
} else {
  cat('✗ tidyverse installation failed\n')
  quit(status = 1)
}

# Check key pharmaverse packages
packagelist <- c('admiral', 'cards', 'teal', 'rtables', 'gtsummary', 'rhino')
for(pkg in packagelist) {
  if(requireNamespace(pkg, quietly = TRUE)) {
    cat('✓', pkg, 'installed successfully\n')
  } else {
    cat('✗', pkg, 'installation failed\n')
    quit(status = 1)
  }
}
cat('\nTidyverse and Pharmaverse packages ready for clinical data analysis!\n')
"

echo -e "\nInstall tidyverse and pharmaverse packages, done!"
