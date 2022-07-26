FROM rocker/tidyverse:4.1.3

LABEL org.opencontainers.image.licenses="GPL-2.0-or-later" \
      org.opencontainers.image.source="https://github.com/rocker-org/rocker-versioned2" \
      org.opencontainers.image.vendor="Rocker Project" \
      org.opencontainers.image.authors="Carl Boettiger <cboettig@ropensci.org>"

ENV CTAN_REPO=https://www.texlive.info/tlnet-archive/2022/04/21/tlnet
ENV PATH=$PATH:/usr/local/texlive/bin/linux
ENV QUARTO_VERSION=1.0.36

RUN /rocker_scripts/install_verse.sh
RUN /rocker_scripts/install_quarto.sh
