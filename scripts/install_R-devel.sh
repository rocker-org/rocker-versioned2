#!/bin/sh
set -e


## ccache can speed compiling later on, but including by default can increase image sizes greatly
#    PATH=/usr/lib/ccache:$PATH


## Runtime library versions are specific to ubuntu:20.04
apt-get update \
  && apt-get install -y --no-install-recommends \
    bash-completion \
    ca-certificates \
    ccache \
    devscripts \
    file \
    fonts-texgyre \
    g++ \
    gfortran \
    gsfonts \
    libblas-dev \
    libbz2-1.0 \
    libcurl4 \
    libicu66 \
    libpcre2-8-0 \
    libjpeg-turbo8 \
    libopenblas-dev \
    libpangocairo-1.0-0 \
    libpng16-16 \
    libreadline8 \
    libtiff5 \
    liblzma5 \
    locales \
    make \
    unzip \
    zip \
    zlib1g

echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen en_US.utf8
/usr/sbin/update-locale LANG=en_US.UTF-8

BUILDDEPS="curl \
    default-jdk \
    libbz2-dev \
    libcairo2-dev \
    libcurl4-openssl-dev \
    libpango1.0-dev \
    libjpeg-dev \
    libicu-dev \
    libpcre2-dev \
    libpng-dev \
    libreadline-dev \
    libtiff5-dev \
    liblzma-dev \
    libx11-dev \
    libxt-dev \
    perl \
    rsync \
    subversion \
    tcl-dev \
    tk-dev \
    texinfo \
    texlive-extra-utils \
    texlive-fonts-recommended \
    texlive-fonts-extra \
    texlive-latex-recommended \
    texlive-latex-extra \
    x11proto-core-dev \
    xauth \
    xfonts-base \
    xvfb \
    zlib1g-dev"

apt-get install -y --no-install-recommends $BUILDDEPS

cd tmp/
svn co https://svn.r-project.org/R/trunk R-devel
cd R-devel
./tools/rsync-recommended
R_PAPERSIZE=letter \
R_BATCHSAVE="--no-save --no-restore" \
R_BROWSER=xdg-open \
PAGER=/usr/bin/pager \
PERL=/usr/bin/perl \
R_UNZIPCMD=/usr/bin/unzip \
R_ZIPCMD=/usr/bin/zip \
R_PRINTCMD=/usr/bin/lpr \
LIBnn=lib \
AWK=/usr/bin/awk \
CFLAGS="-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g" \
CXXFLAGS="-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g" \
./configure --enable-R-shlib \
		   --enable-memory-profiling \
		   --with-readline \
		   --with-blas \
		   --with-tcltk \
		   --disable-nls \
		   --with-recommended-packages
make
make install

## Add a default CRAN mirror
echo "options(repos = c(CRAN = 'https://cran.rstudio.com/'), download.file.method = 'libcurl')" >> /usr/local/lib/R/etc/Rprofile.site
## Add a library directory (for user-installed packages)
mkdir -p /usr/local/lib/R/site-library
chown root:staff /usr/local/lib/R/site-library
chmod g+ws /usr/local/lib/R/site-library

## Fix library path
echo "R_LIBS_USER='/usr/local/lib/R/site-library'" >> /usr/local/lib/R/etc/Renviron
echo "R_LIBS=\${R_LIBS-'/usr/local/lib/R/site-library:/usr/local/lib/R/library:/usr/lib/R/library'}" >> /usr/local/lib/R/etc/Renviron

# If using buildkit, install ccache
if [ "$BUILDKIT_CACHE" == "1" ] ; then
  apt-get install -y --no-install-recommends \
    ccache
fi

## Use littler installation scripts
Rscript -e "install.packages(c('littler', 'docopt'))"
ln -s /usr/local/lib/R/site-library/littler/examples/install2.r /usr/local/bin/install2.r
ln -s /usr/local/lib/R/site-library/littler/examples/installGithub.r /usr/local/bin/installGithub.r
ln -s /usr/local/lib/R/site-library/littler/bin/r /usr/local/bin/r

## Clean up from R source install
cd /
rm -rf /tmp/*
apt-get remove --purge -y $BUILDDEPS
apt-get autoremove -y
apt-get autoclean -y
rm -rf /var/lib/apt/lists/*


