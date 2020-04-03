#!/bin/sh

set -e

export PATH=$PATH:/opt/TinyTeX/bin/x86_64-linux/

## Add LaTeX, rticles and bookdown support
wget "https://travis-bin.yihui.name/texlive-local.deb" \
  && dpkg -i texlive-local.deb \
  && rm texlive-local.deb \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
    cmake \
    default-jdk \
    fonts-roboto \
    ghostscript \
    hugo \
    libbz2-dev \
    libicu-dev \
    liblzma-dev \
    libhunspell-dev \
    libmagick++-dev \
    librdf0-dev \
    libv8-dev \
    qpdf \
    texinfo \
    ssh \
    less \
    vim \
    libzmq3-dev \
    libopenmpi-dev \
  && rm -rf /var/lib/apt/lists/*

install2.r --error -r $CRAN --skipinstalled tinytex

/rocker_scripts/install_texlive.sh

echo "PATH=${PATH}" >> ${R_HOME}/etc/Renviron

install2.r --error --deps TRUE -r $CRAN --skipinstalled \
    blogdown bookdown rticles rmdshower rJava

rm -rf /tmp/downloaded_packages


