#!/bin/bash
set -e

UBUNTUGIS_VERSION=${1:-${UBUNTUGIS_VERSION:-stable}}

## Force installs from SOURCE if using RStudio Package Manager Repository
CRAN=${CRAN/"__linux__/focal"/""}
echo "options(repos = c(CRAN = '${CRAN}'))" >> ${R_HOME}/etc/Rprofile.site

apt-get update \
  && apt-get install -y --no-install-recommends \
  software-properties-common \
  vim \
  wget \
  ca-certificates \
  && add-apt-repository --enable-source --yes "ppa:ubuntugis/ubuntugis-$UBUNTUGIS_VERSION"
