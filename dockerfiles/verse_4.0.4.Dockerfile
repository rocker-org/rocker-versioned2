FROM rocker/tidyverse:4.0.4

LABEL org.opencontainers.image.licenses="GPL-2.0-or-later" \
      org.opencontainers.image.source="https://github.com/rocker-org/rocker-versioned2" \
      org.opencontainers.image.vendor="Rocker Project" \
      org.opencontainers.image.authors="Carl Boettiger <cboettig@ropensci.org>"

ENV CTAN_REPO=https://www.texlive.info/tlnet-archive/2021/03/30/tlnet
ENV PATH=/usr/local/texlive/bin/linux:$PATH

RUN /rocker_scripts/install_verse.sh
