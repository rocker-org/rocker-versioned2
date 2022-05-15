FROM rocker/tidyverse:4.0.0-ubuntu18.04

LABEL org.opencontainers.image.licenses="GPL-2.0-or-later" \
      org.opencontainers.image.source="https://github.com/rocker-org/rocker-versioned2" \
      org.opencontainers.image.vendor="Rocker Project" \
      org.opencontainers.image.authors="Carl Boettiger <cboettig@ropensci.org>"

ENV CTAN_REPO=https://www.texlive.info/tlnet-archive/2020/06/05/tlnet
ENV PATH=/opt/texlive/bin/x86_64-linux:/usr/local/texlive/bin/x86_64-linux:$PATH

RUN /rocker_scripts/install_verse.sh
