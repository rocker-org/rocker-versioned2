#!/bin/bash
set -e

## Install PROJ, GDAL, GEOS from source.
##
## 'latest' means installing the latest release version.

PROJ_VERSION=${PROJ_VERSION:-"latest"}
GDAL_VERSION=${GDAL_VERSION:-"latest"}
GEOS_VERSION=${GEOS_VERSION:-"latest"}

CRAN=${CRAN_SOURCE:-"https://cloud.r-project.org"}
echo "options(repos = c(CRAN = '${CRAN}'))" >>"${R_HOME}/etc/Rprofile.site"

function url_latest_gh_released_asset() {
    wget -qO- "https://api.github.com/repos/$1/releases/latest" | grep -oP "(?<=\"browser_download_url\":\s\")https.*\.tar.gz(?=\")"
}

export DEBIAN_FRONTEND=noninteractive
apt-get -y update &&
    apt-get install -y \
        gdb \
        git \
        libcairo2-dev \
        libcurl4-openssl-dev \
        libexpat1-dev \
        libpq-dev \
        libsqlite3-dev \
        libudunits2-dev \
        make \
        pandoc \
        qpdf \
        sqlite3 \
        subversion \
        valgrind \
        vim \
        tk-dev \
        wget

apt-get install -y \
    libv8-dev \
    libjq-dev \
    libprotobuf-dev \
    libxml2-dev \
    libprotobuf-dev \
    protobuf-compiler \
    unixodbc-dev \
    libssh2-1-dev \
    libgit2-dev \
    libnetcdf-dev \
    locales \
    libssl-dev \
    libtiff-dev

LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

apt-get -y update &&
    apt-get install -y \
        cmake \
        libtiff5-dev

# install proj
# https://download.osgeo.org/proj/
if [ "$PROJ_VERSION" = "latest" ]; then
    PROJ_DL_URL=$(url_latest_gh_released_asset "OSGeo/PROJ")
else
    PROJ_DL_URL="http://download.osgeo.org/proj/proj-${PROJ_VERSION}.tar.gz"
fi

wget "$PROJ_DL_URL" -O proj.tar.gz
tar zxvf proj.tar.gz
cd proj-* &&
    ls -l &&
    mkdir build &&
    cd build &&
    cmake .. &&
    make &&
    make install &&
    cd ../.. &&
    ldconfig

# install gdal
# https://download.osgeo.org/gdal/
if [ "$GDAL_VERSION" = "latest" ]; then
    GDAL_DL_URL=$(url_latest_gh_released_asset "OSGeo/gdal")
else
    GDAL_DL_URL="https://download.osgeo.org/gdal/${GDAL_VERSION}/gdal-${GDAL_VERSION}.tar.gz"
fi

wget "$GDAL_DL_URL" -O gdal.tar.gz &&
    tar -xf gdal.tar.gz &&
    rm ./*.tar.gz &&
    cd gdal* &&
    ./configure &&
    make &&
    make install &&
    cd .. &&
    ldconfig

# install geos
# https://libgeos.org/usage/download/
if [ "$GEOS_VERSION" = "latest" ]; then
    GEOS_VERSION=$(wget -qO- "https://api.github.com/repos/libgeos/geos/git/refs/tags" | grep -oP "(?<=\"ref\":\s\"refs/tags/)\d+\.\d+\.\d+" | tail -n -1)
fi

wget http://download.osgeo.org/geos/geos-"${GEOS_VERSION}".tar.bz2 &&
    bzip2 -d geos-*bz2 &&
    tar xf geos*tar &&
    rm ./*.tar &&
    cd geos* &&
    ./configure &&
    make &&
    make install &&
    cd .. &&
    ldconfig

Rscript -e 'install.packages(c("sp", "rgeos", "rgdal", "RPostgreSQL", "RSQLite", "testthat", "knitr", "tidyr", "geosphere", "maptools", "maps", "microbenchmark", "raster", "dplyr", "tibble", "units", "DBI",  "covr", "protolite", "tmap", "mapview", "odbc", "pool", "rmarkdown", "RPostgres","spatstat", "stars"))'

git clone --depth 10 https://github.com/r-spatial/sf.git
git clone --depth 10 https://github.com/r-spatial/lwgeom.git
git clone --depth 10 https://github.com/r-spatial/stars.git

R CMD build --no-build-vignettes --no-manual lwgeom
R CMD build --no-build-vignettes --no-manual sf
R CMD INSTALL sf
R CMD INSTALL lwgeom
R CMD build --no-build-vignettes --no-manual stars
R CMD INSTALL stars

# Clean up
rm -rf /var/lib/apt/lists/*
