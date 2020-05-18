#!/bin/bash

set -e

# always set this for scripts but don't declare as ENV..
export DEBIAN_FRONTEND=noninteractive


export PATH=$PATH:/usr/local/texlive/bin/x86_64-linux/

apt-get update -qq \
  && apt-get install -y --no-install-recommends \
    cmake \
    curl \
    default-jdk \
    fonts-roboto \
    ghostscript \
    hugo \
    less \
    libbz2-dev \
    libhunspell-dev \
    libicu-dev \
    liblzma-dev \
    libmagick++-dev \
    libopenmpi-dev \
    libpcre2-dev \
    libssl-dev \
    libv8-dev \
    libzmq3-dev \
    lsb-release \
    qpdf \
    texinfo \
    software-properties-common \
    ssh \
    vim \
    wget


# 
# librdf0-dev depends on libcurl4-gnutils-dev instead of libcurl4-openssl-dev... 
# So: we can build the redland package bindings and then swap back to libcurl-openssl-dev... (ick)
apt-get install -y librdf0-dev
install2.r --error --skipinstalled -r $CRAN redland
apt-get install -y libcurl4-openssl-dev && apt-get -y autoremove

# libgit2-dev also depends on the libcurl4-gnutils in bionic but not on focal
# cran PPA is a super-stable solution to this
UBUNTU_VERSION=${UBUNTU_VERSION:-`lsb_release -sc`}
if [ ${UBUNTU_VERSION} == "bionic" ]; then 
  add-apt-repository -y ppa:cran/travis
fi
apt-get install -y libgit2-dev libcurl4-openssl-dev



## Add LaTeX, rticles and bookdown support
wget "https://travis-bin.yihui.name/texlive-local.deb" \
  && dpkg -i texlive-local.deb \
  && rm texlive-local.deb


## Install texlive
rocker_scripts/install_texlive.sh

install2.r --error -r $CRAN --skipinstalled tinytex
install2.r --error --deps TRUE -r $CRAN --skipinstalled \
    blogdown bookdown rticles rmdshower rJava

rm -rf /tmp/downloaded_packages
rm -rf /var/lib/apt/lists/*


