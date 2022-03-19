#!/bin/bash
set -e

CRAN=${CRAN:-"https://cran.r-project.org"}

##  mechanism to force source installs if we're using RSPM
UBUNTU_VERSION=$(lsb_release -sc)
CRAN_SOURCE=${CRAN/"__linux__/$UBUNTU_VERSION/"/""}

## source install if using RSPM and arm64 image
if [ "$(uname -m)" = "aarch64" ]; then
    CRAN=$CRAN_SOURCE
fi

## Add a default CRAN mirror
echo "options(repos = c(CRAN = '${CRAN}'), download.file.method = 'libcurl')" >>"${R_HOME}/etc/Rprofile.site"

## Set HTTPUserAgent for RSPM (https://github.com/rocker-org/rocker/issues/400)
cat <<EOF >>"${R_HOME}/etc/Rprofile.site"
# https://docs.rstudio.com/rspm/admin/serving-binaries/#binaries-r-configuration-linux
options(HTTPUserAgent = sprintf("R/%s R (%s)", getRversion(), paste(getRversion(), R.version["platform"], R.version["arch"], R.version["os"])))
EOF

## Use littler installation scripts
Rscript -e "install.packages(c('littler', 'docopt'), repos='${CRAN_SOURCE}')"
ln -s "${R_HOME}/site-library/littler/bin/r" /usr/local/bin/r
ln -s "${R_HOME}/site-library/littler/examples/installGithub.r" /usr/local/bin/installGithub.r

## Use rocker scripts version install2.r if it exists
if [ -f "/rocker_scripts/bin/install2.r" ]; then
    ln -sf /rocker_scripts/bin/install2.r /usr/local/bin/install2.r
else
    ln -s "${R_HOME}/site-library/littler/examples/install2.r" /usr/local/bin/install2.r
fi
