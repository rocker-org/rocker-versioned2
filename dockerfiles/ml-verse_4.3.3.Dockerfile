FROM rocker/ml:4.3.3

LABEL org.opencontainers.image.licenses="GPL-2.0-or-later" \
      org.opencontainers.image.source="https://github.com/rocker-org/rocker-versioned2" \
      org.opencontainers.image.vendor="Rocker Project" \
      org.opencontainers.image.authors="Carl Boettiger <cboettig@ropensci.org>"

ENV CTAN_REPO=https://mirror.ctan.org/systems/texlive/tlnet

RUN /rocker_scripts/install_verse.sh
RUN /rocker_scripts/install_geospatial.sh
