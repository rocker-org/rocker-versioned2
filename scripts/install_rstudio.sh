#!/bin/bash
set -e


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

if [ -z "$RSTUDIO_VERSION_ARG" ] || [ "$RSTUDIO_VERSION_ARG" = "latest" ]; then
    DOWNLOAD_VERSION=`wget -qO - https://rstudio.com/products/rstudio/download-server/debian-ubuntu/ | grep -oP "(?<=rstudio-server-)[0-9]\.[0-9]\.[0-9]+" | sort | tail -n 1`
elif [ "$RSTUDIO_VERSION_ARG" = "preview" ]; then
    DOWNLOAD_VERSION=`wget -qO - https://rstudio.com/products/rstudio/download/preview/ | grep -oP "(?<=rstudio-server-)[0-9]\.[0-9]\.[0-9]+" | sort | tail -n 1`
elif [ "$RSTUDIO_VERSION_ARG" = "daily" ]; then
    DOWNLOAD_VERSION=`wget -qO - https://dailies.rstudio.com/rstudioserver/oss/ubuntu/x86_64/ | grep -oP "(?<=rstudio-server-)[0-9]\.[0-9]\.[0-9]+" | sort | tail -n 1`
else
    DOWNLOAD_VERSION=${RSTUDIO_VERSION_ARG}
fi


## UBUNTU_VERSION is not generally valid: only works for xenial and bionic, not other releases,
## and does not understand numeric versions. (2020-04-15)
#RSTUDIO_URL="https://s3.amazonaws.com/rstudio-ide-build/server/${UBUNTU_VERSION}/amd64/rstudio-server-${DOWNLOAD_VERSION}-amd64.deb"
## hardwire bionic for now...
RSTUDIO_URL="https://s3.amazonaws.com/rstudio-ide-build/server/bionic/amd64/rstudio-server-${DOWNLOAD_VERSION}-amd64.deb"

if [ "$UBUNTU_VERSION" = "xenial" ]; then
  wget $RSTUDIO_URL || \
  wget `echo $RSTUDIO_URL | sed 's/server-/server-xenial-/'` || \
  wget `echo $RSTUDIO_URL | sed 's/xenial/trusty/'`
else
  wget $RSTUDIO_URL
fi

dpkg -i rstudio-server-*-amd64.deb
rm rstudio-server-*-amd64.deb

## RStudio wants an /etc/R, will populate from $R_HOME/etc
mkdir -p /etc/R
echo "PATH=${PATH}" >> ${R_HOME}/etc/Renviron

## Make RStudio compatible with case when R is built from source 
## (and thus is at /usr/local/bin/R), because RStudio doesn't obey
## path if a user apt-get installs a package
R_BIN=`which R`
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

# set up default user 
/rocker_scripts/default_user.sh

# install user config initiation script 
cp /rocker_scripts/userconf.sh /etc/cont-init.d/userconf
cp /rocker_scripts/pam-helper.sh /usr/lib/rstudio-server/bin/pam-helper

## Rocker's default RStudio settings, for better reproducibility
mkdir -p /home/rstudio/.rstudio/monitored/user-settings \
  && echo 'alwaysSaveHistory="0" \
          \nloadRData="0" \
          \nsaveAction="0"' \
          > /home/rstudio/.rstudio/monitored/user-settings/user-settings \
  && chown -R rstudio:rstudio /home/rstudio/.rstudio

## 
git config --system credential.helper 'cache --timeout=3600'



