FROM shug0131/tidyverse:4.3.1

LABEL org.opencontainers.image.licenses="GPL-2.0-or-later" \
      org.opencontainers.image.source="https://github.com/rocker-org/rocker-versioned2" \
      org.opencontainers.image.vendor="Rocker Project" \
      org.opencontainers.image.authors="Carl Boettiger <cboettig@ropensci.org>"

ENV CTAN_REPO=https://www.texlive.info/tlnet-archive/2023/10/30/tlnet
ENV PATH=$PATH:/usr/local/texlive/bin/linux
ENV LANG=en_US.UTF-8

RUN /rocker_scripts/install_verse.sh
