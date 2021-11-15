#!/bin/bash
set -e

DEFAULT_USER=${DEFAULT_USER:-rstudio}

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
    sudo \
    wget

rm -rf /var/lib/apt/lists/*

# install s6 supervisor
/rocker_scripts/install_s6init.sh

## Download and install RStudio server & dependencies
## Uses, in order of preference, first argument of the script, the
## RSTUDIO_VERSION variable, or the latest RStudio version.  "latest", "preview",
## or "daily" may be used.
##
## Also symlinks pandoc, pandoc-citeproc so they are available system-wide,
export PATH=/usr/lib/rstudio-server/bin:$PATH

# Get RStudio. Use version from environment variable, or take version from
# first argument.
if [ -z "$1" ];
  then RSTUDIO_VERSION_ARG=$RSTUDIO_VERSION;
  else RSTUDIO_VERSION_ARG=$1;
fi

RSTUDIO_BASE_URL=https://download2.rstudio.org/server

if [ -z "$RSTUDIO_VERSION_ARG" ] || [ "$RSTUDIO_VERSION_ARG" = "latest" ]; then
    DOWNLOAD_VERSION=$(wget -qO - https://rstudio.com/products/rstudio/download-server/debian-ubuntu/ | grep -oP "(?<=rstudio-server-)[0-9]+\.[0-9]+\.[0-9]+-[0-9]+" -m 1)
elif [ "$RSTUDIO_VERSION_ARG" = "preview" ]; then
    DOWNLOAD_VERSION=$(wget -qO - https://rstudio.com/products/rstudio/download/preview/ | grep -oP "(?<=rstudio-server-)[0-9]+\.[0-9]+\.[0-9]+-preview%2B[0-9]+" -m 1 ||
      wget -qO - https://rstudio.com/products/rstudio/download/preview/ | grep -oP "(?<=rstudio-server-)[0-9]+\.[0-9]+\.[0-9]+%2B[0-9]+" -m 1)
    RSTUDIO_BASE_URL=https://s3.amazonaws.com/rstudio-ide-build/server
elif [ "$RSTUDIO_VERSION_ARG" = "daily" ]; then
    DOWNLOAD_VERSION=$(wget -qO - https://dailies.rstudio.com/rstudio/latest/index.json | grep -oP "(?<=rstudio-server-)[0-9]+\.[0-9]+\.[0-9]+-daily-[0-9]+(?=-amd64.deb)" -m 1)
    RSTUDIO_BASE_URL=https://s3.amazonaws.com/rstudio-ide-build/server
else
    DOWNLOAD_VERSION=${RSTUDIO_VERSION_ARG/"+"/"-"}
fi

## UBUNTU_VERSION is not generally valid: only works for xenial and bionic, not other releases,
## and does not understand numeric versions. (2020-04-15)
#RSTUDIO_URL="${RSTUDIO_BASE_URL}/${UBUNTU_VERSION}/amd64/rstudio-server-${DOWNLOAD_VERSION}-amd64.deb"
## hardwire bionic for now...
RSTUDIO_URL="${RSTUDIO_BASE_URL}/bionic/amd64/rstudio-server-${DOWNLOAD_VERSION}-amd64.deb"

if [ "$UBUNTU_VERSION" = "xenial" ]; then
  wget "${RSTUDIO_URL}" || \
  wget "${RSTUDIO_URL//server-/server-xenial-/}" || \
  wget "${RSTUDIO_URL//xenial/trusty/}"
else
  wget "${RSTUDIO_URL}"
fi

dpkg -i rstudio-server-*-amd64.deb
rm rstudio-server-*-amd64.deb

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
logger-type=stderr
"

printf "%s" "$LOGGING" > /etc/rstudio/logging.conf

# set up default user
/rocker_scripts/default_user.sh

# install user config initiation script
cp /rocker_scripts/userconf.sh /etc/cont-init.d/userconf
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
