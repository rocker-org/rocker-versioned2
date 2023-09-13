#!/bin/bash
set -e

## Install PROJ, GDAL, GEOS from source.
##
## 'latest' means installing the latest release version.

## build ARGs
NCPUS=${NCPUS:-"-1"}
PROJ_VERSION=${PROJ_VERSION:-"latest"}
GDAL_VERSION=${GDAL_VERSION:-"latest"}
GEOS_VERSION=${GEOS_VERSION:-"latest"}
CRAN=${CRAN_SOURCE:-"https://cloud.r-project.org"}
echo "options(repos = c(CRAN = '${CRAN}'))" >>"${R_HOME}/etc/Rprofile.site"

# cmake does not understand "-1" as "all cpus"
CMAKE_CORES=${NCPUS}
if [ "${CMAKE_CORES}" = "-1" ]; then
CMAKE_CORES=$(nproc --all)
fi

# a function to install apt packages only if they are not installed
function apt_install() {
  if ! dpkg -s "$@" >/dev/null 2>&1; then
  if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
  apt-get update
  fi
  apt-get install -y --no-install-recommends "$@"
  fi
}

function url_latest_gh_released_asset() {
  wget -qO- "https://api.github.com/repos/$1/releases/latest" | grep -oP "(?<=\"browser_download_url\":\s\")https.*\.tar.gz(?=\")" | head -n 1
}

# a function to remove apt packages only if they are installed
function apt_remove() {
  if dpkg -s "$@" >/dev/null 2>&1; then
  apt-get remove -y "$@"
  fi
}


export DEBIAN_FRONTEND=noninteractive
apt_remove gdal-bin libgdal-dev libgeos-dev libproj-dev \
&& apt-get autoremove -y

JAVA_VERSION=17

apt-get update && apt-get -y install \
  git \
  lsb-release \
  libcairo2-dev \
  libcurl4-openssl-dev \
  libpq-dev \
  libsqlite3-dev \
  make \
  pandoc \
  qpdf \
  sqlite3 \
  valgrind \
  vim \
  wget \
  libnode-dev \
  libjq-dev \
  libssh-dev \
  libgit2-dev \
  locales \
  libssl-dev \
  python3-dev python3-numpy python3-setuptools \
  libpng-dev libjpeg-dev libgif-dev liblzma-dev \
  curl libxml2-dev libexpat-dev libxerces-c-dev \
  libnetcdf-dev libpoppler-dev libpoppler-private-dev \
  swig ant libhdf4-alt-dev libhdf5-dev \
  libfreexl-dev unixodbc-dev  mdbtools-dev libwebp-dev \
  liblcms2-2 libpcre3-dev libcrypto++-dev libfyba-dev \
  libkml-dev libmysqlclient-dev libogdi-dev \
  libcfitsio-dev openjdk-"$JAVA_VERSION"-jdk libzstd-dev \
  libpq-dev libssl-dev libboost-dev \
  autoconf automake bash-completion libarmadillo-dev \
  libopenexr-dev libheif-dev \
  libdeflate-dev libblosc-dev liblz4-dev libbz2-dev \
  libbrotli-dev \
  libarchive-dev \
  libaec-dev

## geoparquet support
wget https://apache.jfrog.io/artifactory/arrow/"$(lsb_release --id --short | tr '[:upper:]' '[:lower:]')"/apache-arrow-apt-source-latest-"$(lsb_release --codename --short)".deb
apt_install -y -V ./apache-arrow-apt-source-latest-"$(lsb_release --codename --short)".deb
apt-get update && apt-get install -y -V libarrow-dev libparquet-dev libarrow-dataset-dev

LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
rm -rf /build_local
mkdir /build_local && cd /build_local

## purge existing directories to permit re-run of script with updated versions
rm -rf geos* proj* gdal*

# install geos
# https://libgeos.org/usage/download/
if [ "$GEOS_VERSION" = "latest" ]; then
GEOS_VERSION=$(wget -qO- "https://api.github.com/repos/libgeos/geos/git/refs/tags" | grep -oP "(?<=\"ref\":\s\"refs/tags/)\d+\.\d+\.\d+" | tail -n -1)
fi
  
wget https://download.osgeo.org/geos/geos-"${GEOS_VERSION}".tar.bz2
bzip2 -d geos-*bz2
tar xf geos*tar
rm geos*tar
cd geos*
mkdir build
cd build
cmake ..
cmake --build . --parallel "$CMAKE_CORES" --target install
ldconfig
cd /build_local

# install proj
# https://download.osgeo.org/proj/
if [ "$PROJ_VERSION" = "latest" ]; then
PROJ_DL_URL=$(url_latest_gh_released_asset "OSGeo/PROJ")
else
  PROJ_DL_URL="https://download.osgeo.org/proj/proj-${PROJ_VERSION}.tar.gz"
fi

wget "$PROJ_DL_URL" -O proj.tar.gz
tar zxvf proj.tar.gz
rm proj.tar.gz
cd proj-*
mkdir build
cd build
cmake ..
cmake --build . --parallel "$CMAKE_CORES" --target install
ldconfig
cd /build_local

# install gdal
# https://download.osgeo.org/gdal/
if [ "$GDAL_VERSION" = "latest" ]; then
GDAL_DL_URL=$(url_latest_gh_released_asset "OSGeo/gdal")
else
  GDAL_DL_URL="https://download.osgeo.org/gdal/${GDAL_VERSION}/gdal-${GDAL_VERSION}.tar.gz"
fi

wget "$GDAL_DL_URL" -O gdal.tar.gz
tar -xf gdal.tar.gz
rm gdal*tar.gz
cd gdal*
mkdir build
cd ./build
# cmake .. -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX=/usr   -DBUILD_JAVA_BINDINGS:BOOL=OFF -DBUILD_CSHARP_BINDINGS:BOOL=OFF
cmake -DCMAKE_BUILD_TYPE=Release ..
cmake --build . --parallel "$CMAKE_CORES" --target install
ldconfig
cd /build_local

# R package dependencies
apt-get -y install cargo libudunits2-dev

install2.r --error --skipmissing -n "$NCPUS" -r ${CRAN_SOURCE} \
  sf \
  terra \
  lwgeom \
  stars \
  gdalcubes \
  gifski

# Clean up
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/downloaded_packages

# Check the geospatial packages

echo -e "Check the stars package...\n"
R -q -e "library(stars)"
echo -e "\nInstall stars package, done!"