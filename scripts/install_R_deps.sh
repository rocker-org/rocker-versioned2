#!/bin/bash


set -e

R_VERSION=${1:-${R_VERSION:-"latest"}}

# shellcheck source=/dev/null
source /etc/os-release

apt-get update
apt-get -y install locales

## Configure default locale
LANG=${LANG:-"en_US.UTF-8"}
/usr/sbin/locale-gen --lang "${LANG}"
/usr/sbin/update-locale --reset LANG="${LANG}"

export DEBIAN_FRONTEND=noninteractive

R_HOME=${R_HOME:-"/usr/local/lib/R"}

READLINE_VERSION=8
if [ "${UBUNTU_CODENAME}" == "bionic" ]; then
    READLINE_VERSION=7
fi

apt-get install -y --no-install-recommends \
    bash-completion \
    ca-certificates \
    file \
    fonts-texgyre \
    g++ \
    gfortran \
    gsfonts \
    libblas-dev \
    libbz2-* \
    libcurl4 \
    "libicu[0-9][0-9]" \
    liblapack-dev \
    libpcre2* \
    libjpeg-turbo* \
    libpangocairo-* \
    libpng16* \
    "libreadline${READLINE_VERSION}" \
    libtiff* \
    liblzma* \
    make \
    tzdata \
    unzip \
    zip \
    zlib1g


mkdir -p "${R_HOME}/site-library" 
chown root:staff "${R_HOME}/site-library"
chmod g+ws "${R_HOME}/site-library"
echo "R_LIBS=\${R_LIBS-'${R_HOME}/site-library:${R_HOME}/library'}" >>"${R_HOME}/etc/Renviron.site"

echo "PATH=${PATH}" >>"${R_HOME}/etc/Renviron.site"


