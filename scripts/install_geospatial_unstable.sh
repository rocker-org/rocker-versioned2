#!/bin/bash
set -e

CRAN=${CRAN_SOURCE:-"https://cloud.r-project.org"}

# always set this for scripts but don't declare as ENV..
export DEBIAN_FRONTEND=noninteractive
apt-get update && apt-get install -y --no-install-recommends \
  gnupg2 curl ca-certificates

apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 6B827C12C2D425E227EDCA75089EBE08314DF160
echo "deb http://ppa.launchpad.net/ubuntugis/ubuntugis-unstable/ubuntu focal main" >> /etc/apt/sources.list.d/ubuntugis.list
echo "deb-src http://ppa.launchpad.net/ubuntugis/ubuntugis-unstable/ubuntu focal main" >> /etc/apt/sources.list.d/ubuntugis.list
rm -rf /var/lib/apt/lists/*

## in UNSTABLE, we will install everything from source by default:
echo "options(repos = c(CRAN = '${CRAN}'))" >>"${R_HOME}/etc/Rprofile.site"
