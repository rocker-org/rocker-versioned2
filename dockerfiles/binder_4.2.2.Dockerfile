FROM rocker/geospatial:4.2.2

LABEL org.opencontainers.image.licenses="GPL-2.0-or-later" \
      org.opencontainers.image.source="https://github.com/rocker-org/rocker-versioned2" \
      org.opencontainers.image.vendor="Rocker Project" \
      org.opencontainers.image.authors="Carl Boettiger <cboettig@ropensci.org>"

ENV NB_USER=rstudio

RUN /rocker_scripts/install_jupyter.sh

EXPOSE 8888

CMD ["/bin/sh", "-c", "jupyter lab --ip 0.0.0.0 --no-browser"]

USER ${NB_USER}

WORKDIR /home/${NB_USER}
