#!/bin/bash

GDAL_VERSION=3.1.2
GEOS_VERSION=3.8.0
PROJ_VERSION=7.1.0
#LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH


apt-get update \
  && apt-get install -y --no-install-recommends \
    lbzip2 \
    libdap-dev \
    libexpat1-dev \
    libfftw3-dev \
    libfreexl-dev \
    libgsl0-dev \
    libglu1-mesa-dev \
    libhdf4-alt-dev \
    libhdf5-dev \
    libkml-dev \
    libnetcdf-dev \
    libsqlite3-dev \
    libssl-dev \
    libtcl8.6 \
    libtk8.6 \
    libtiff5-dev \
    libudunits2-dev \
    libxerces-c-dev \
    unixodbc-dev

wget http://download.osgeo.org/gdal/${GDAL_VERSION}/gdal-${GDAL_VERSION}.tar.gz
tar -xf gdal-${GDAL_VERSION}.tar.gz
rm gdal-${GDAL_VERSION}.tar.gz

wget http://download.osgeo.org/geos/geos-${GEOS_VERSION}.tar.bz2
tar -xf geos-${GEOS_VERSION}.tar.bz2
rm geos-${GEOS_VERSION}.tar.bz2

wget http://download.osgeo.org/proj/proj-${PROJ_VERSION}.tar.gz
tar -xf proj-${PROJ_VERSION}.tar.gz
rm proj-${PROJ_VERSION}.tar.gz


## Install proj
cd /proj*
./configure
make
make install



## Install libgeos
cd /geos*
./configure
make
make install

## Configure options loosely based on homebrew gdal2 https://github.com/OSGeo/homebrew-osgeo4mac/blob/master/Formula/gdal2.rb
cd /gdal*
./configure \
    --with-curl \
    --with-dods-root=/usr \
    --with-freexl \
    --with-geos \
    --with-geotiff \
    --with-hdf4 \
    --with-hdf5=/usr/lib/x86_64-linux-gnu/hdf5/serial \
    --with-libjson-c \
    --with-netcdf \
    --with-odbc \
    --without-grass \
    --without-libgrass
make
make install

cd ..
## Cleanup gdal & geos installation
rm -rf gdal-* geos-*

CRAN_SOURCE=`echo ${CRAN} | sed s/__linux__\/focal/`
install2.r -e -r $CRAN_SOURCE lwgeom rgdal rgeos proj4 sf stars


