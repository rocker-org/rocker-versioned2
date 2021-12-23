#!/bin/bash
set -e

## build ARGs
NCPUS=${NCPUS:--1}

# always set this for scripts but don't declare as ENV..
export DEBIAN_FRONTEND=noninteractive
export PATH=$PATH:/usr/local/texlive/bin/x86_64-linux/

apt-get update

#----- SysDeps for Tidyverse-----
apt-get install -y --no-install-recommends \
    file \
    git \
    libapparmor1 \
    libgc1c2 \
    libclang-dev \
    libcurl4-openssl-dev \
    libedit2 \
    libobjc4 \
    libssl-dev \
    libpq5 \
    lsb-release \
    psmisc \
    procps \
    python-setuptools \
    pwgen \
    sudo \
    wget

#----- SysDeps for Verse-----
apt-get install -y --no-install-recommends \
    cmake \
    default-jdk \
    fonts-roboto \
    ghostscript \
    hugo \
    less \
    libbz2-dev \
    libglpk-dev \
    libgmp3-dev \
    libfribidi-dev \
    libharfbuzz-dev \
    libhunspell-dev \
    libicu-dev \
    liblzma-dev \
    libmagick++-dev \
    libopenmpi-dev \
    libpcre2-dev \
    libv8-dev \
    libxml2-dev\
    libxslt1-dev \
    libzmq3-dev \
    qpdf \
    texinfo \
    software-properties-common \
    vim

# librdf0-dev depends on libcurl4-gnutils-dev instead of libcurl4-openssl-dev...
# So: we can build the redland package bindings and then swap back to libcurl-openssl-dev... (ick)
# explicitly install runtime library sub-deps of librdf0-dev so they are not auto-removed.
apt-get install -y librdf0-dev
install2.r --error --skipinstalled -n $NCPUS redland
apt-get install -y \
	libcurl4-openssl-dev \
	libxslt-dev \
	librdf0 \
	redland-utils \
	rasqal-utils \
	raptor2-utils \
        && apt-get remove -y systemd \
	&& apt-get -y autoremove

apt-get install -y libgit2-dev libcurl4-openssl-dev

## Add LaTeX, rticles and bookdown support
wget "https://travis-bin.yihui.name/texlive-local.deb" \
  && dpkg -i texlive-local.deb \
  && rm texlive-local.deb

## Install texlive and pandoc
/rocker_scripts/install_texlive.sh
/rocker_scripts/install_pandoc.sh

#----- SysDeps for Geospatial-----

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
    libudunits2-dev \
    lsb-release \
    netcdf-bin \
    postgis \
    protobuf-compiler \
    sqlite3 \
    tk-dev \
    unixodbc-dev


#----- Cleanup -----
rm -rf /var/lib/apt/lists/*

