#!/bin/bash
set -e

# always set this for scripts but don't declare as ENV..
export DEBIAN_FRONTEND=noninteractive

## build ARGs
NCPUS=${NCPUS:--1}

apt-get update
apt-get install -y --no-install-recommends \
    gdal-bin \
    lbzip2 \
    libfftw3-dev \
    libgdal-dev \
    libgeos-dev \
    libgsl0-dev \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    libhdf4-alt-dev \
    libhdf5-dev \
    libjq-dev \
    libpq-dev \
    libproj-dev \
    libprotobuf-dev \
    libnetcdf-dev \
    libsqlite3-dev \
    libssl-dev \
    libudunits2-dev \
    lsb-release \
    netcdf-bin \
    postgis \
    protobuf-compiler \
    sqlite3 \
    tk-dev \
    unixodbc-dev

# lwgeom 0.2-2 and 0.2-3 have a regression which prevents install on ubuntu:bionic
## permissionless PAT for builds
UBUNTU_VERSION=$(lsb_release -sc)
if [ "${UBUNTU_VERSION}" == "bionic" ]; then
    R -e "remotes::install_version('lwgeom', '0.2-4')"
fi

## Somehow foreign is messed up on CRAN between 2020-04-25 -- 2020-05-0?
##install2.r --error --skipinstalled --repo https://mran.microsoft.com/snapshot/2020-04-24 -n $NCPUS foreign

install2.r --error --skipinstalled -n "$NCPUS" \
    RColorBrewer \
    RandomFields \
    RNetCDF \
    classInt \
    deldir \
    gstat \
    hdf5r \
    lidR \
    mapdata \
    maptools \
    mapview \
    ncdf4 \
    proj4 \
    raster \
    rgdal \
    rgeos \
    rlas \
    sf \
    sp \
    spacetime \
    spatstat \
    spatialreg \
    spdep \
    stars \
    terra \
    tidync \
    tmap \
    geoR \
    geosphere \
    BiocManager

R -e "BiocManager::install('rhdf5')"

## install wgrib2 for NOAA's NOMADS / rNOMADS forecast files
/rocker_scripts/install_wgrib2.sh

# Clean up
rm -rf /var/lib/apt/lists/*
rm -r /tmp/downloaded_packages
