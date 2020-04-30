#!/bin/sh

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
    librdf0-dev \
    libssl-dev \
    libv8-dev \
    libzmq3-dev \
    qpdf \
    texinfo \
    ssh \
    vim \
    wget \
  && rm -rf /var/lib/apt/lists/*

## Add LaTeX, rticles and bookdown support
wget "https://travis-bin.yihui.name/texlive-local.deb" \
  && dpkg -i texlive-local.deb \
  && rm texlive-local.deb

install2.r --error -r $CRAN --skipinstalled tinytex
install2.r --error --deps TRUE -r $CRAN --skipinstalled \
    blogdown bookdown rticles rmdshower rJava

rm -rf /tmp/downloaded_packages


