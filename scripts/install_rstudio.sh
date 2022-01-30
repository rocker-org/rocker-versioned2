#!/bin/bash

## Download and install RStudio server & dependencies uses.
## Also symlinks pandoc, pandoc-citeproc so they are available system-wide.
##
## In order of preference, first argument of the script, the RSTUDIO_VERSION variable.
## ex. stable, preview, daily, 1.3.959, 2021.09.1+372, 2021.09.1-372, 2022.06.0-daily+11

set -e

RSTUDIO_VERSION=${1:-${RSTUDIO_VERSION:-"stable"}}

DEFAULT_USER=${DEFAULT_USER:-rstudio}
ARCH=$(dpkg --print-architecture)

apt-get update
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

rm -rf /var/lib/apt/lists/*

# install s6 supervisor
/rocker_scripts/install_s6init.sh

export PATH=/usr/lib/rstudio-server/bin:$PATH


## Download RStudio Server for Ubuntu 18+
DOWNLOAD_FILE=rstudio-server.deb

if [ "$RSTUDIO_VERSION" = "latest" ]; then
  RSTUDIO_VERSION="stable"
fi

if [ "$RSTUDIO_VERSION" = "stable" ] || [ "$RSTUDIO_VERSION" = "preview" ] || [ "$RSTUDIO_VERSION" = "daily" ]; then
  wget "https://rstudio.org/download/latest/${RSTUDIO_VERSION}/server/bionic/rstudio-server-latest-${ARCH}.deb" -O "$DOWNLOAD_FILE"
else
  wget "https://download2.rstudio.org/server/bionic/${ARCH}/rstudio-server-${RSTUDIO_VERSION/"+"/"-"}-${ARCH}.deb" -O "$DOWNLOAD_FILE" \
  || wget "https://s3.amazonaws.com/rstudio-ide-build/server/bionic/${ARCH}/rstudio-server-${RSTUDIO_VERSION/"+"/"-"}-${ARCH}.deb" -O "$DOWNLOAD_FILE"
fi

dpkg -i "$DOWNLOAD_FILE"
rm "$DOWNLOAD_FILE"

# https://github.com/rocker-org/rocker-versioned2/issues/137
rm -f /var/lib/rstudio-server/secure-cookie-key

## RStudio wants an /etc/R, will populate from $R_HOME/etc
mkdir -p /etc/R
echo "PATH=${PATH}" >> ${R_HOME}/etc/Renviron.site

## Make RStudio compatible with case when R is built from source
## (and thus is at /usr/local/bin/R), because RStudio doesn't obey
## path if a user apt-get installs a package
R_BIN=$(which R)
echo "rsession-which-r=${R_BIN}" > /etc/rstudio/rserver.conf
## use more robust file locking to avoid errors when using shared volumes:
echo "lock-type=advisory" > /etc/rstudio/file-locks

## Prepare optional configuration file to disable authentication
## To de-activate authentication, `disable_auth_rserver.conf` script
## will just need to be overwrite /etc/rstudio/rserver.conf.
## This is triggered by an env var in the user config
cp /etc/rstudio/rserver.conf /etc/rstudio/disable_auth_rserver.conf
echo "auth-none=1" >> /etc/rstudio/disable_auth_rserver.conf

## Set up RStudio init scripts
mkdir -p /etc/services.d/rstudio
# shellcheck disable=SC2016
echo '#!/usr/bin/with-contenv bash
## load /etc/environment vars first:
for line in $( cat /etc/environment ) ; do export $line > /dev/null; done
exec /usr/lib/rstudio-server/bin/rserver --server-daemonize 0' \
> /etc/services.d/rstudio/run

echo '#!/bin/bash
rstudio-server stop' \
> /etc/services.d/rstudio/finish

# If CUDA enabled, make sure RStudio knows (config_cuda_R.sh handles this anyway)
if [ ! -z "$CUDA_HOME" ]; then
  sed -i '/^rsession-ld-library-path/d' /etc/rstudio/rserver.conf
  echo "rsession-ld-library-path=$LD_LIBRARY_PATH" >> /etc/rstudio/rserver.conf
fi

# Log to stderr
LOGGING="[*]
log-level=warn
logger-type=syslog
"

printf "%s" "$LOGGING" > /etc/rstudio/logging.conf

# set up default user
/rocker_scripts/default_user.sh

# install user config initiation script
cp /rocker_scripts/init_set_env.sh /etc/cont-init.d/01_set_env
cp /rocker_scripts/init_userconf.sh /etc/cont-init.d/02_userconf
cp /rocker_scripts/pam-helper.sh /usr/lib/rstudio-server/bin/pam-helper

## Rocker's default RStudio settings, for better reproducibility

USER_SETTINGS='alwaysSaveHistory="0"
loadRData="0"
saveAction="0"
'

mkdir -p /home/${DEFAULT_USER}/.rstudio/monitored/user-settings \
  && printf "%s" "$USER_SETTINGS" \
          > /home/${DEFAULT_USER}/.rstudio/monitored/user-settings/user-settings \
  && chown -R ${DEFAULT_USER}:${DEFAULT_USER} /home/${DEFAULT_USER}/.rstudio

git config --system credential.helper 'cache --timeout=3600'
