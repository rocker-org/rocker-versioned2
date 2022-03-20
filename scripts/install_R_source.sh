#!/bin/bash

## Install R from source.
##
## In order of preference, first argument of the script, the R_VERSION variable.
## ex. latest, devel, patched, 4.0.0
##
## 'devel' means the latest daily snapshot of current development version.
## 'pached' means the latest daily snapshot of current pached version.

set -e

R_VERSION=${1:-${R_VERSION:-"latest"}}

apt-get update
apt-get -y install locales lsb-release

## Configure default locale, see https://github.com/docker-library/docs/tree/master/ubuntu#locales
localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
LANG=${LANG:-"en_US.UTF-8"}

UBUNTU_VERSION=$(lsb_release -sc)

export DEBIAN_FRONTEND=noninteractive

R_HOME=${R_HOME:-"/usr/local/lib/R"}

READLINE_VERSION=8
OPENBLAS=libopenblas-dev
if [ "${UBUNTU_VERSION}" == "bionic" ]; then
    READLINE_VERSION=7
    OPENBLAS=libopenblas-dev
fi

apt-get install -y --no-install-recommends \
    bash-completion \
    ca-certificates \
    devscripts \
    file \
    fonts-texgyre \
    g++ \
    gfortran \
    gsfonts \
    libblas-dev \
    libbz2-* \
    libcurl4 \
    libicu* \
    liblapack-dev \
    libpcre2* \
    libjpeg-turbo* \
    libpangocairo-* \
    libpng16* \
    "libreadline${READLINE_VERSION}" \
    libtiff* \
    liblzma* \
    make \
    unzip \
    zip \
    zlib1g

BUILDDEPS="curl \
    default-jdk \
    libbz2-dev \
    libcairo2-dev \
    libcurl4-openssl-dev \
    libpango1.0-dev \
    libjpeg-dev \
    libicu-dev \
    libpcre2-dev \
    libpng-dev \
    libreadline-dev \
    libtiff5-dev \
    liblzma-dev \
    libx11-dev \
    libxt-dev \
    perl \
    rsync \
    subversion \
    tcl-dev \
    tk-dev \
    texinfo \
    texlive-extra-utils \
    texlive-fonts-recommended \
    texlive-fonts-extra \
    texlive-latex-recommended \
    texlive-latex-extra \
    x11proto-core-dev \
    xauth \
    xfonts-base \
    xvfb \
    wget \
    zlib1g-dev"

# shellcheck disable=SC2086
apt-get install -y --no-install-recommends ${BUILDDEPS}

if [[ "$R_VERSION" == "devel" ]] || [[ "$R_VERSION" == "patched" ]]; then
    wget "https://stat.ethz.ch/R/daily/R-${R_VERSION}.tar.gz"
elif [[ "$R_VERSION" == "latest" ]]; then
    wget "https://cloud.r-project.org/src/base/R-latest.tar.gz" ||
        wget "https://cran.r-project.org/src/base/R-latest.tar.gz"
else
    wget "https://cloud.r-project.org/src/base/R-${R_VERSION%%.*}/R-${R_VERSION}.tar.gz" ||
        wget "https://cran.r-project.org/src/base/R-${R_VERSION%%.*}/R-${R_VERSION}.tar.gz"
fi

tar xzf "R-${R_VERSION}.tar.gz"
cd "R-${R_VERSION}"

R_PAPERSIZE=letter \
    R_BATCHSAVE="--no-save --no-restore" \
    R_BROWSER=xdg-open \
    PAGER=/usr/bin/pager \
    PERL=/usr/bin/perl \
    R_UNZIPCMD=/usr/bin/unzip \
    R_ZIPCMD=/usr/bin/zip \
    R_PRINTCMD=/usr/bin/lpr \
    LIBnn=lib \
    AWK=/usr/bin/awk \
    CFLAGS="-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g" \
    CXXFLAGS="-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g" \
    ./configure --enable-R-shlib \
    --enable-memory-profiling \
    --with-readline \
    --with-blas \
    --with-lapack \
    --with-tcltk \
    --with-recommended-packages

make
make install
make clean

## Install OpenBLAS after R is compiled
## https://github.com/rocker-org/rocker-versioned2/issues/390
ARCH=$(uname -m)
apt-get install -y --no-install-recommends "${OPENBLAS}"
update-alternatives --set "libblas.so.3-${ARCH}-linux-gnu" "/usr/lib/${ARCH}-linux-gnu/openblas-pthread/libblas.so.3"

## Add a library directory (for user-installed packages)
mkdir -p "${R_HOME}/site-library"
chown root:staff "${R_HOME}/site-library"
chmod g+ws "${R_HOME}/site-library"

## Fix library path
echo "R_LIBS=\${R_LIBS-'${R_HOME}/site-library:${R_HOME}/library'}" >>"${R_HOME}/etc/Renviron.site"

## Clean up from R source install
cd /
rm -rf /tmp/*
rm -rf "R-${R_VERSION}"
rm -rf "R-${R_VERSION}.tar.gz"

# shellcheck disable=SC2086
apt-get remove --purge -y ${BUILDDEPS}
apt-get autoremove -y
apt-get autoclean -y
rm -rf /var/lib/apt/lists/*
