#!/bin/sh
set -e

echo "deb http://cloud.r-project.org/bin/linux/ubuntu ${UBUNTU_VERSION}-cran35/" >> /etc/apt/sources.list
gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9
gpg -a --export E298A3A825C0D65DFD57CBB651716619E084DAB9 | apt-key add - 
apt-get update
apt-get -y install --no-install-recommends \
      ca-certificates \
      less \
      littler \
      libopenblas-base \
      locales \
      r-base-dev \
      vim-tiny \
      wget
rm -rf /var/lib/apt/lists/*

echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen en_US.utf8
/usr/sbin/update-locale LANG=${LANG}

Rscript -e "install.packages(c('littler', 'docopt'))"
ln -s /usr/lib/R/site-library/littler/examples/install.r /usr/local/bin/install.r
ln -s /usr/lib/R/site-library/littler/examples/install2.r /usr/local/bin/install2.r
ln -s /usr/lib/R/site-library/littler/examples/installGithub.r /usr/local/bin/installGithub.r
ln -s /usr/local/lib/R/site-library/littler/bin/r /usr/local/bin/r


