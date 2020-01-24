#!/bin/sh
set -e

### Sets up S6 supervisor.

S6_VERSION=${S6_VERSION:-v1.21.7.0}
S6_BEHAVIOUR_IF_STAGE2_FAILS=2

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


