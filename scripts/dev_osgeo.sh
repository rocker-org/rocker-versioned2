#!/bin/bash
set -e

CRAN=${CRAN_SOURCE:-https://cran.r-project.org}
echo "options(repos = c(CRAN = '${CRAN}'), download.file.method = 'libcurl')" >> "${R_HOME}/etc/Rprofile.site"

export DEBIAN_FRONTEND=noninteractive; apt-get -y update \
  && apt-get install -y \
	gdb \
	git \
	libcairo2-dev \
	libcurl4-openssl-dev \
	libexpat1-dev \
	libpq-dev \
	libsqlite3-dev \
	libudunits2-dev \
	make \
	pandoc \
	qpdf \
  	sqlite3 \
	subversion \
	valgrind \
	vim \
	tk-dev \
	wget

apt-get install -y \
	libv8-dev \
	libjq-dev \
	libprotobuf-dev \
	libxml2-dev \
	libprotobuf-dev \
	protobuf-compiler \
	unixodbc-dev \
	libssh2-1-dev \
	libgit2-dev \
	libnetcdf-dev \
	locales \
	libssl-dev \
	libtiff-dev

locale-gen en_US.UTF-8

PROJ_VERSION=${PROJ_VERSION:-7.2.0}
LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

export DEBIAN_FRONTEND=noninteractive; apt-get -y update \
  && apt-get install -y \
	cmake \
	libtiff5-dev

#git clone --depth 1 https://github.com/OSGeo/PROJ.git
wget http://download.osgeo.org/proj/proj-$PROJ_VERSION.tar.gz
tar zxvf proj-${PROJ_VERSION}.tar.gz
cd proj-${PROJ_VERSION} \
  && ls -l \
  && mkdir build \
  && cd build \
  && cmake .. \
  && make \
  && make install \
  && cd ../.. \
  && ldconfig

# install proj-data:
#cd /usr/local/share/proj \
#  && wget http://download.osgeo.org/proj/proj-data-1.1RC1.zip \
#  && unzip -o proj-data*zip \
#  && rm proj-data*zip \
#  && cd -

# GDAL:

# https://download.osgeo.org/gdal/
GDAL_VERSION=${GDAL_VERSION:-3.2.0}
GDAL_VERSION_NAME=${GDAL_VERSION}

wget http://download.osgeo.org/gdal/${GDAL_VERSION}/gdal-${GDAL_VERSION_NAME}.tar.gz \
  && tar -xf gdal-${GDAL_VERSION_NAME}.tar.gz \
  && rm *.tar.gz \
  && cd gdal* \
  && ./configure \
  && make \
  && make install \
  && cd .. \
  && ldconfig

#git clone --depth 1 https://github.com/OSGeo/gdal.git
#cd gdal/gdal \
#  && ls -l \
#  && ./configure \
#  && make \
#  && make install \
#  && cd .. \
#  && ldconfig

# GEOS:
GEOS_VERSION=${GEOS_VERSION:-3.8.1}

wget http://download.osgeo.org/geos/geos-${GEOS_VERSION}.tar.bz2 \
  && bzip2 -d geos-*bz2 \
  && tar xf geos*tar \
  && rm *.tar \
  && cd geos* \
  && ./configure \
  && make \
  && make install \
  && cd .. \
  && ldconfig

# svn  checkout svn://scm.r-forge.r-project.org/svnroot/rgdal/
# R CMD build rgdal/pkg --no-build-vignettes
# R CMD INSTALL rgdal_*.tar.gz

Rscript -e 'install.packages(c("sp", "rgeos", "rgdal", "RPostgreSQL", "RSQLite", "testthat", "knitr", "tidyr", "geosphere", "maptools", "maps", "microbenchmark", "raster", "dplyr", "tibble", "units", "DBI",  "covr", "protolite", "tmap", "mapview", "odbc", "pool", "rmarkdown", "RPostgres","spatstat", "stars"))'

git clone --depth 10 https://github.com/r-spatial/sf.git
git clone --depth 10 https://github.com/r-spatial/lwgeom.git
git clone --depth 10 https://github.com/r-spatial/stars.git
#git config --global user.email "edzer.pebesma@uni-muenster.de"

R CMD build --no-build-vignettes --no-manual lwgeom
(cd sf; git pull)
R CMD build --no-build-vignettes --no-manual sf
# pkg-config proj --modversion
R CMD INSTALL sf
R CMD INSTALL lwgeom
R CMD build --no-build-vignettes --no-manual stars
R CMD INSTALL stars
