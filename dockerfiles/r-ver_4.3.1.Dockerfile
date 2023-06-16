FROM ubuntu:jammy

LABEL org.opencontainers.image.licenses="GPL-2.0-or-later" \
      org.opencontainers.image.source="https://github.com/rocker-org/rocker-versioned2" \
      org.opencontainers.image.vendor="Rocker Project" \
      org.opencontainers.image.authors="Carl Boettiger <cboettig@ropensci.org>"

ENV R_VERSION=4.3.1
ENV R_HOME=/usr/local/lib/R
ENV TZ=Etc/UTC

COPY scripts/install_R_source.sh /rocker_scripts/install_R_source.sh

RUN /rocker_scripts/install_R_source.sh

ENV CRAN=https://packagemanager.posit.co/cran/__linux__/jammy/latest
ENV LANG=en_US.UTF-8

COPY scripts /rocker_scripts

RUN /rocker_scripts/setup_R.sh

CMD ["R"]
