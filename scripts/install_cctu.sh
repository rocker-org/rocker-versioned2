#!/bin/bash
set -e


NCPUS=${NCPUS:--1}

install2.r --error  --skipmissing --deps TRUE --skipinstalled -n "$NCPUS"  xslt
R -q -e "remotes::install_github(repo=\"shug0131/cctu\", ref=\"$CCTU_VERSION\" )"


install2.r --error  --skipmissing --deps TRUE --skipinstalled -n "$NCPUS" \
    kableExtra \
    reshape2 \
    mvtnorm \
    ggalluvial \
    patchwork \
    writexl \
    openxlsx \
    gee \
    lme4 \
    eudract \
    ordinal \
    consort \
    coxme \
    mice
#   Hmisc \ # frnak harrells package of stuff
#   mfp \ # fractional polynomials
#  stan packages ?? seem to be there as dependencies..somewhere
#


# Clean up
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/downloaded_packages

## Strip binary installed lybraries from RSPM
## https://github.com/rocker-org/rocker-versioned2/issues/340
strip /usr/local/lib/R/site-library/*/libs/*.so

# Check the cctu version
echo -e "Check the cctu package...\n"

R -q -e "library(cctu)"

echo -e "\nInstall cctu, and other routine packages, done!"
