FROM rocker/verse:4.3.1

LABEL org.opencontainers.image.licenses="GPL-2.0-or-later" \
      org.opencontainers.image.source="https://github.com/rocker-org/rocker-versioned2" \
      org.opencontainers.image.vendor="Rocker Project" \
      org.opencontainers.image.authors="Carl Boettiger <cboettig@ropensci.org>"

ENV PROJ_VERSION=9.2.1
ENV GDAL_VERSION=3.7.0
ENV GEOS_VERSION=3.12.0

COPY scripts/experimental/install_dev_osgeo.sh /rocker_scripts/experimental/install_dev_osgeo.sh

RUN /rocker_scripts/experimental/install_dev_osgeo.sh
