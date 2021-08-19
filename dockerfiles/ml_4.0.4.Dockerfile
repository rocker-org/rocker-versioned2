FROM rocker/cuda:4.0.4

LABEL org.opencontainers.image.licenses="GPL-2.0-or-later" \
      org.opencontainers.image.source="https://github.com/rocker-org/rocker-versioned2" \
      org.opencontainers.image.vendor="Rocker Project" \
      org.opencontainers.image.authors="Carl Boettiger <cboettig@ropensci.org>"

ENV S6_VERSION=v1.21.7.0
ENV RSTUDIO_VERSION=1.4.1106
ENV PANDOC_VERSION=default
ENV TENSORFLOW_VERSION=gpu
ENV KERAS_VERSION=default
ENV PATH=/usr/lib/rstudio-server/bin:$PATH


RUN /rocker_scripts/install_rstudio.sh
RUN /rocker_scripts/install_pandoc.sh
RUN /rocker_scripts/install_tidyverse.sh
RUN /rocker_scripts/install_tensorflow.sh

EXPOSE 8787

CMD ["/init"]



