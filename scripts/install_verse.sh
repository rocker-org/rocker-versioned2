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

## Admin-based install of TinyTeX:
wget -qO- \
    "https://github.com/yihui/tinytex/raw/master/tools/install-unx.sh" | \
    sh -s - --admin --no-path \
  && mv ~/.TinyTeX /opt/TinyTeX \
  && /opt/TinyTeX/bin/*/tlmgr path add \
  && tlmgr install metafont mfware inconsolata tex ae parskip listings \
  && tlmgr path add \
  && Rscript -e "tinytex::r_texmf()" \
  && chown -R root:staff /opt/TinyTeX \
  && chown -R root:staff ${R_HOME}/site-library \
  && chmod -R g+w /opt/TinyTeX \
  && chmod -R g+wx /opt/TinyTeX/bin \
  && echo "PATH=${PATH}" >> ${R_HOME}/etc/Renviron
 

install2.r --error --deps TRUE -r $CRAN --skipinstalled \
    blogdown bookdown rticles rmdshower rJava


