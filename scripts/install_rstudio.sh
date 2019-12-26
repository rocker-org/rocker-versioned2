#!/bin/sh
set -e

## Download and install RStudio server & dependencies
## Uses, in order of preference, first argument of the script, the
## RSTUDIO_VERSION variable, or the latest RStudio version.  "latest", "preview",
## or "daily" may be used.
##
## Also symlinks pandoc, pandoc-citeproc so they are available system-wide,
## And sets up S6 supervisor

S6_VERSION=${S6_VERSION:-v1.21.7.0}
S6_BEHAVIOUR_IF_STAGE2_FAILS=2
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

RSTUDIO_URL="https://s3.amazonaws.com/rstudio-ide-build/server/${UBUNTU_VERSION}/amd64/rstudio-server-${DOWNLOAD_VERSION}-amd64.deb"

if [ "$UBUNTU_VERSION" = "xenial" ]; then
  wget $RSTUDIO_URL || \
  wget `echo $RSTUDIO_URL | sed 's/server-/server-xenial-/'` || \
  wget `echo $RSTUDIO_URL | sed 's/xenial/trusty/'`
else
  wget $RSTUDIO_URL
fi

apt-get update
apt-get install -y --no-install-recommends \
    file \
    git \
    libapparmor1 \
    libcurl4-openssl-dev \
    libedit2 \
    libssl-dev \
    lsb-release \
    psmisc \
    procps \
    python-setuptools \
    sudo \
    wget \
    libclang-dev \
    libobjc4 \
    libgc1c2
rm -rf /var/lib/apt/lists/*

dpkg -i rstudio-server-*-amd64.deb
rm rstudio-server-*-amd64.deb

## Symlink pandoc & standard pandoc templates for use system-wide
ln -s /usr/lib/rstudio-server/bin/pandoc/pandoc /usr/local/bin
ln -s /usr/lib/rstudio-server/bin/pandoc/pandoc-citeproc /usr/local/bin
PANDOC_TEMPLATES_VERSION=`pandoc -v | grep -oP "(?<=pandoc\s)[0-9\.]+$"`
git clone --recursive --branch ${PANDOC_TEMPLATES_VERSION} https://github.com/jgm/pandoc-templates
mkdir -p /opt/pandoc/templates
cp -r pandoc-templates*/* /opt/pandoc/templates && rm -rf pandoc-templates*
mkdir /root/.pandoc && ln -s /opt/pandoc/templates /root/.pandoc/templates


## RStudio wants an /etc/R, will populate from $R_HOME/etc
mkdir -p /etc/R
echo "PATH=${PATH}" >> ${R_HOME}/etc/Renviron

## Need to configure non-root user for RStudio
useradd rstudio
echo "rstudio:rstudio" | chpasswd
mkdir /home/rstudio
chown rstudio:rstudio /home/rstudio
addgroup rstudio staff
  ## Prevent rstudio from deciding to use /usr/bin/R if a user apt-get installs a package

R_BIN=`which R`
echo "rsession-which-r=${R_BIN}" >> /etc/rstudio/rserver.conf
## use more robust file locking to avoid errors when using shared volumes:
echo "lock-type=advisory" >> /etc/rstudio/file-locks

## Optional configuration file to disable authentication
cp /etc/rstudio/rserver.conf /etc/rstudio/disable_auth_rserver.conf
echo "auth-none=1" >> /etc/rstudio/disable_auth_rserver.conf

## configure git not to request password each time
git config --system credential.helper 'cache --timeout=3600'
git config --system push.default simple

## Set up S6 init system
wget -P /tmp/ https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/s6-overlay-amd64.tar.gz
tar xzf /tmp/s6-overlay-amd64.tar.gz -C /
mkdir -p /etc/services.d/rstudio
echo "#!/usr/bin/with-contenv bash \
          \n## load /etc/environment vars first: \
          \n for line in $( cat /etc/environment ) ; do export $line > /dev/null; done \
          \n exec /usr/lib/rstudio-server/bin/rserver --server-daemonize 0" \
          > /etc/services.d/rstudio/run
echo "#!/bin/bash \
          \n rstudio-server stop" \
          > /etc/services.d/rstudio/finish
mkdir -p /home/rstudio/.rstudio/monitored/user-settings
echo "alwaysSaveHistory='0' \
          \nloadRData='0' \
          \nsaveAction='0'" \
          > /home/rstudio/.rstudio/monitored/user-settings/user-settings
chown -R rstudio:rstudio /home/rstudio/.rstudio

