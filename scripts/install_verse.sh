#!/bin/bash

set -e

export PATH=$PATH:/opt/TinyTeX/bin/x86_64-linux/

apt-get update \
  && apt-get install -y --no-install-recommends \
    cmake \
    curl \
    default-jdk \
    fonts-roboto \
    ghostscript \
    hugo \
    less \
    libbz2-dev \
    libcurl4-openssl-dev \
    libhunspell-dev \
    libicu-dev \
    liblzma-dev \
    libmagick++-dev \
    libopenmpi-dev \
    libpcre2-dev \
    libssl-dev \
    libv8-dev \
    libzmq3-dev \
    qpdf \
    texinfo \
    ssh \
    vim \
    wget \
  && rm -rf /var/lib/apt/lists/*


# 
# librdf0-dev depends on libcurl4-gnutils-dev instead of libcurl4-openssl-dev... 
# We can build the redland package bindings and then swap back to libcurl-openssl-dev... (ick)
apt-get install -y librdf0-dev
install2.r --error --skipinstalled -r $CRAN redland
apt-get install -y libcurl4-openssl-dev


## Add LaTeX, rticles and bookdown support
wget "https://travis-bin.yihui.name/texlive-local.deb" \
  && dpkg -i texlive-local.deb \
  && rm texlive-local.deb

install2.r --error -r $CRAN --skipinstalled tinytex
install2.r --error --deps TRUE -r $CRAN --skipinstalled \
    blogdown bookdown rticles rmdshower rJava

rm -rf /tmp/downloaded_packages


