FROM rocker/verse:4.1.2

LABEL org.opencontainers.image.licenses="GPL-2.0-or-later" \
      org.opencontainers.image.source="https://github.com/rocker-org/rocker-versioned2" \
      org.opencontainers.image.vendor="Rocker Project" \
      org.opencontainers.image.authors="Carl Boettiger <cboettig@ropensci.org>"

ENV PROJ_VERSION=7.2.0
ENV GDAL_VERSION=3.2.0
ENV GEOS_VERSION=3.8.1

RUN /rocker_scripts/dev_osgeo.sh
