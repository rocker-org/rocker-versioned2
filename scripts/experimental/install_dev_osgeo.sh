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

CRAN_SOURCE=${CRAN_SOURCE:-"https://cloud.r-project.org"}
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

# a function to remove apt packages only if they are installed
function apt_remove() {
    if dpkg -s "$@" >/dev/null 2>&1; then
        apt-get remove -y "$@"
    fi
}

function url_latest_gh_released_asset() {
    wget -qO- "https://api.github.com/repos/$1/releases/latest" | grep -oP "(?<=\"browser_download_url\":\s\")https.*\.tar.gz(?=\")" | head -n 1
}

export DEBIAN_FRONTEND=noninteractive

apt_remove gdal-bin libgdal-dev libgeos-dev libproj-dev &&
    apt-get autoremove -y

## Derived from osgeo/gdal
apt-get update
apt-get install -y --fix-missing --no-install-recommends \
    ant \
    autoconf \
    automake \
    bash-completion \
    build-essential \
    ca-certificates \
    cmake \
    curl \
    git \
    libarchive-dev \
    libarmadillo-dev \
    libblosc-dev \
    libboost-dev \
    libbz2-dev \
    libcairo2-dev \
    libclc-15-dev \
    libcfitsio-dev \
    libcrypto++-dev \
    libcurl4-openssl-dev \
    libdeflate-dev \
    libexpat-dev \
    libfreexl-dev \
    libfyba-dev \
    libgif-dev \
    libheif-dev \
    libhdf4-alt-dev \
    libhdf5-serial-dev \
    libjpeg-dev \
    libkml-dev \
    liblcms2-2 \
    liblerc-dev \
    liblz4-dev \
    liblzma-dev \
    libmysqlclient-dev \
    libnetcdf-dev \
    libogdi-dev \
    libopenexr-dev \
    libopenjp2-7-dev \
    libpcre3-dev \
    libpng-dev \
    libpq-dev \
    libpoppler-dev \
    libpoppler-private-dev \
    libqhull-dev \
    libsqlite3-dev \
    libssl-dev \
    libtiff5-dev \
    libudunits2-dev \
    libwebp-dev \
    libxerces-c-dev \
    libxml2-dev \
    lsb-release \
    make \
    mdbtools-dev \
    pkg-config \
    python3-dev \
    python3-numpy \
    python3-setuptools \
    sqlite3 \
    swig \
    unixodbc-dev \
    wget \
    zlib1g-dev
## geoparquet support
wget https://apache.jfrog.io/artifactory/arrow/"$(lsb_release --id --short | tr '[:upper:]' '[:lower:]')"/apache-arrow-apt-source-latest-"$(lsb_release --codename --short)".deb
apt_install -y -V ./apache-arrow-apt-source-latest-"$(lsb_release --codename --short)".deb
apt-get update && apt-get install -y -V libarrow-dev libparquet-dev libarrow-dataset-dev

rm -rf /build_local
mkdir /build_local && cd /build_local

## tiledb
GCC_ARCH="$(uname -m)"
export TILEDB_VERSION=2.16.3
apt-get update -y &&
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        libspdlog-dev &&
    mkdir tiledb &&
    wget -q https://github.com/TileDB-Inc/TileDB/archive/${TILEDB_VERSION}.tar.gz -O - |
    tar xz -C tiledb --strip-components=1 &&
    cd tiledb &&
    mkdir build_cmake &&
    cd build_cmake &&
    ../bootstrap --prefix=/usr --disable-werror &&
    make "-j$(nproc)" &&
    make install-tiledb DESTDIR="/build_thirdparty" &&
    make install-tiledb &&
    cd ../.. &&
    rm -rf tiledb &&
    for i in /build_thirdparty/usr/lib/"${GCC_ARCH}"-linux-gnu/*; do strip -s "$i" 2>/dev/null || /bin/true; done &&
    for i in /build_thirdparty/usr/bin/*; do strip -s "$i" 2>/dev/null || /bin/true; done

LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

# install geos
# https://libgeos.org/usage/download/
if [ "$GEOS_VERSION" = "latest" ]; then
    GEOS_VERSION=$(wget -qO- "https://api.github.com/repos/libgeos/geos/git/refs/tags" | grep -oP "(?<=\"ref\":\s\"refs/tags/)\d+\.\d+\.\d+" | tail -n -1)
fi

## purge existing directories to permit re-run of script with updated versions
rm -rf geos* proj* gdal*

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

apt-get update && apt-get -y install cargo

install2.r --error --skipmissing -n "$NCPUS" -r "${CRAN_SOURCE}" \
    sf \
    terra \
    lwgeom \
    stars \
    gdalcubes

# Clean up
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/downloaded_packages

# Check the geospatial packages

echo -e "Check the stars package...\n"
R -q -e "library(stars)"
echo -e "\nInstall stars package, done!"
