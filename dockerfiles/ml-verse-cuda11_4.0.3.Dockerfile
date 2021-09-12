FROM rocker/ml:4.0.3-cuda11.1

LABEL org.opencontainers.image.licenses="GPL-2.0-or-later" \
      org.opencontainers.image.source="https://github.com/rocker-org/rocker-versioned2" \
      org.opencontainers.image.vendor="Rocker Project" \
      org.opencontainers.image.authors="Carl Boettiger <cboettig@ropensci.org>"

ENV CTAN_REPO=http://www.texlive.info/tlnet-archive/2021/02/14/tlnet

RUN /rocker_scripts/install_verse.sh
RUN /rocker_scripts/install_geospatial.sh
