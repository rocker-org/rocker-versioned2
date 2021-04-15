#!/bin/bash
set -e

SHINY_SERVER_VERSION=${1:-${SHINY_SERVER_VERSION:-latest}}

# Run dependency scripts
. /rocker_scripts/install_s6init.sh
. /rocker_scripts/install_pandoc.sh

if [ "$SHINY_SERVER_VERSION" = "latest" ]; then
  SHINY_SERVER_VERSION=$(wget -qO- https://download3.rstudio.org/ubuntu-14.04/x86_64/VERSION)
fi

# Get apt packages
apt-get update
apt-get install -y --no-install-recommends \
    sudo \
    gdebi-core \
    libcurl4-gnutls-dev \
    libcairo2-dev \
    libxt-dev \
    xtail \
    wget

# Install Shiny server
wget --no-verbose "https://download3.rstudio.org/ubuntu-14.04/x86_64/shiny-server-${SHINY_SERVER_VERSION}-amd64.deb" -O ss-latest.deb
gdebi -n ss-latest.deb
rm ss-latest.deb

# Get R packages
install2.r --error --skipinstalled shiny rmarkdown

# Set up directories and permissions
if [ -x "$(command -v rstudio-server)" ]; then
  DEFAULT_USER=${DEFAULT_USER:-rstudio}
  adduser ${DEFAULT_USER} shiny
fi

cp -R /usr/local/lib/R/site-library/shiny/examples/* /srv/shiny-server/
chown shiny:shiny /var/lib/shiny-server
mkdir -p /var/log/shiny-server
chown shiny:shiny /var/log/shiny-server

# create init scripts
mkdir -p /etc/services.d/shiny-server
cat > /etc/services.d/shiny-server/run << 'EOF'
#!/usr/bin/with-contenv bash
## load /etc/environment vars first:
for line in $( cat /etc/environment ) ; do export $line > /dev/null; done
if [ "$APPLICATION_LOGS_TO_STDOUT" != "false" ]; then
    exec xtail /var/log/shiny-server/ &
fi
exec shiny-server 2>&1
EOF
chmod +x /etc/services.d/shiny-server/run

# Clean up
rm -rf /var/lib/apt/lists/*
