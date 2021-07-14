#!/bin/bash
set -e

apt-get update && apt-get -y install lsb-release

UBUNTU_VERSION=${UBUNTU_VERSION:-`lsb_release -sc`}
CRAN_LINUX_VERSION=${CRAN_LINUX_VERSION:-cran40}
LANG=${LANG:-en_US.UTF-8}
LC_ALL=${LC_ALL:-en_US.UTF-8}
CRAN=${CRAN:-https://cran.r-project.org}

##  mechanism to force source installs if we're using RSPM
CRAN_SOURCE=${CRAN/"__linux__/$UBUNTU_VERSION/"/""}

export DEBIAN_FRONTEND=noninteractive

# Set up and install R
R_HOME=${R_HOME:-/usr/lib/R}

READLINE_VERSION=8
OPENBLAS=libopenblas-dev
if [ ${UBUNTU_VERSION} == "bionic" ]; then
  READLINE_VERSION=7
  OPENBLAS=libopenblas-dev
fi

apt-get update

apt-get -y install --no-install-recommends \
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
      libpcre2* \
      libjpeg-turbo* \
      ${OPENBLAS} \
      libpangocairo-* \
      libpng16* \
      libreadline${READLINE_VERSION} \
      libtiff* \
      liblzma* \
      make \
      unzip \
      zip \
      zlib1g \
      less \
      locales \
      vim-tiny \
      wget \
      dirmngr \
      gpg \
      gpg-agent

echo "deb http://cloud.r-project.org/bin/linux/ubuntu ${UBUNTU_VERSION}-${CRAN_LINUX_VERSION}/" >> /etc/apt/sources.list

gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9
gpg -a --export E298A3A825C0D65DFD57CBB651716619E084DAB9 | apt-key add -


# Wildcard * at end of version will grab (latest) patch of requested version
apt-get update && apt-get -y install --no-install-recommends r-base-dev=${R_VERSION}*

rm -rf /var/lib/apt/lists/*

## Add PPAs: NOTE this will mean that installing binary R packages won't be version stable.
##
## These are required at least for bionic-based images since 3.4 r binaries are

echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen en_US.utf8
/usr/sbin/update-locale LANG=${LANG}

## Add a default CRAN mirror
echo "options(repos = c(CRAN = '${CRAN}'), download.file.method = 'libcurl')" >> ${R_HOME}/etc/Rprofile.site

## Set HTTPUserAgent for RSPM (https://github.com/rocker-org/rocker/issues/400)
echo  'options(HTTPUserAgent = sprintf("R/%s R (%s)", getRversion(),
                 paste(getRversion(), R.version$platform,
                       R.version$arch, R.version$os)))' >> ${R_HOME}/etc/Rprofile.site

## Add a library directory (for user-installed packages)
mkdir -p ${R_HOME}/site-library
chown root:staff ${R_HOME}/site-library
chmod g+ws ${R_HOME}/site-library

## Fix library path
echo "R_LIBS=\${R_LIBS-'${R_HOME}/site-library:${R_HOME}/library'}" >> ${R_HOME}/etc/Renviron
echo "TZ=${TZ}" >> ${R_HOME}/etc/Renviron

## Use littler installation scripts
Rscript -e "install.packages(c('littler', 'docopt'), repos='${CRAN_SOURCE}')"
ln -s ${R_HOME}/site-library/littler/examples/install2.r /usr/local/bin/install2.r
ln -s ${R_HOME}/site-library/littler/examples/installGithub.r /usr/local/bin/installGithub.r
ln -s ${R_HOME}/site-library/littler/bin/r /usr/local/bin/r
