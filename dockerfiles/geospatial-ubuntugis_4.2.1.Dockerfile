FROM rocker/verse:4.2.1

LABEL org.opencontainers.image.licenses="GPL-2.0-or-later" \
      org.opencontainers.image.source="https://github.com/rocker-org/rocker-versioned2" \
      org.opencontainers.image.vendor="Rocker Project" \
      org.opencontainers.image.authors="Carl Boettiger <cboettig@ropensci.org>"

COPY scripts/experimental/install_geospatial_unstable.sh /rocker_scripts/experimental/install_geospatial_unstable.sh

RUN /rocker_scripts/experimental/install_geospatial_unstable.sh
