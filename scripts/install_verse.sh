#!/bin/bash
set -e

## build ARGs
NCPUS=${NCPUS:--1}

# always set this for scripts but don't declare as ENV..
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends \
    cmake \
    curl \
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
    libssl-dev \
    libv8-dev \
    libxml2-dev \
    libxslt1-dev \
    libzmq3-dev \
    lsb-release \
    qpdf \
    texinfo \
    software-properties-common \
    vim \
    wget

# libgit2-dev also depends on the libcurl4-gnutils in bionic but not on focal
# cran PPA is a super-stable solution to this
UBUNTU_VERSION=$(lsb_release -sc)
if [ "${UBUNTU_VERSION}" == "bionic" ]; then
    add-apt-repository -y ppa:cran/travis
fi

# librdf0-dev depends on libcurl4-gnutils-dev instead of libcurl4-openssl-dev...
# So: we can build the redland package bindings and then swap back to libcurl-openssl-dev... (ick)
# explicitly install runtime library sub-deps of librdf0-dev so they are not auto-removed.
apt-get install -y librdf0-dev
install2.r --error --skipinstalled -n "$NCPUS" redland
apt-get install -y \
    libcurl4-openssl-dev \
    libxslt-dev \
    librdf0 \
    redland-utils \
    rasqal-utils \
    raptor2-utils &&
    apt-get remove -y systemd &&
    apt-get -y autoremove

apt-get install -y libgit2-dev libcurl4-openssl-dev

## Add LaTeX, rticles and bookdown support
wget "https://travis-bin.yihui.name/texlive-local.deb"
dpkg -i texlive-local.deb
rm texlive-local.deb

## Install texlive
/rocker_scripts/install_texlive.sh

install2.r --error --skipinstalled -n "$NCPUS" tinytex
install2.r --error --deps TRUE --skipinstalled -n "$NCPUS" \
    blogdown \
    bookdown \
    distill \
    rticles \
    rmdshower \
    rJava \
    xaringan

rm -rf /tmp/downloaded_packages
rm -rf /var/lib/apt/lists/*
