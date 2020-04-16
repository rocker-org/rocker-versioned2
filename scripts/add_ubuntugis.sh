#!/bin/bash

set -e

UBUNTUGIS_VERSION=${1:-${UBUNTUGIS_VERSION:-stable}}


apt-get update \
  && apt-get install -y --no-install-recommends \
  software-properties-common \
  vim \
  wget \
  ca-certificates \
  && add-apt-repository --enable-source --yes "ppa:ubuntugis/ubuntugis-$UBUNTUGIS_VERSION"


