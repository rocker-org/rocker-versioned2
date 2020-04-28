#!/bin/bash


## attempt install of liblwgeom-dev, which is
## not in focal (ubuntu-20.04) 
apt-get update && apt-get install -y --no-install-recommends liblwgeom-dev

## now error on errors
set -e

apt-get update \
  && apt-get install -y --no-install-recommends \
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
    netcdf-bin \
    postgis \
    protobuf-compiler \
    sqlite3 \
    tk-dev \
    unixodbc-dev

# lwgeom 0.2-2 and 0.2-3 have a regression which prevents install on ubuntu:bionic
## permissionless PAT for builds

if [UBUNTU_VERSION == bionic]; then 
  GITHUB_PAT=0e7777db4b3bb48acb542b8912a989b8047f6351 && \
    R -e "remotes::install_github('r-spatial/lwgeom')"
fi


## Somehow foreign is messed up on CRAN between 2020-04-25 -- ??
install2.r --error --skipinstalled --repo https://mran.microsoft.com/snapshot/2020-04-24 foreign

install2.r --error --skipinstalled \
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
    tidync \
    tmap \
    geoR \
    geosphere

R -e "BiocManager::install('rhdf5')"

rm -r /tmp/downloaded_packages
