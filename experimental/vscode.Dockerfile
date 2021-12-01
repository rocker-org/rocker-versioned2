FROM nvidia/cuda:11.1.1-cudnn8-devel-ubuntu20.04

LABEL org.opencontainers.image.licenses="GPL-2.0-or-later" \
      org.opencontainers.image.source="https://github.com/rocker-org/rocker-versioned2" \
      org.opencontainers.image.vendor="Rocker Project" \
      org.opencontainers.image.authors="Carl Boettiger <cboettig@ropensci.org>"

ENV R_VERSION=4.1.2
ENV TERM=xterm
ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV R_HOME=/usr/local/lib/R
ENV CRAN=https://packagemanager.rstudio.com/cran/__linux__/focal/latest
ENV TZ=Etc/UTC
ENV NVBLAS_CONFIG_FILE=/etc/nvblas.conf
ENV WORKON_HOME=/opt/venv
ENV PYTHON_VENV_PATH=/opt/venv/reticulate
ENV PYTHON_CONFIGURE_OPTS=--enable-shared
ENV RETICULATE_AUTOCONFIGURE=0
ENV PATH=${PYTHON_VENV_PATH}/bin:${PATH}:${CUDA_HOME}/bin
ENV CTAN_REPO=http://mirror.ctan.org/systems/texlive/tlnet

COPY scripts /rocker_scripts
RUN /rocker_scripts/install_R.sh
RUN /rocker_scripts/config_R_cuda.sh
RUN /rocker_scripts/install_python.sh
RUN /rocker_scripts/install_tidyverse.sh
RUN /rocker_scripts/install_verse.sh
RUN /rocker_scripts/install_geospatial.sh

COPY experimental/scripts /rocker_scripts/experimental
RUN /rocker_scripts/experimental/install_vscode.sh
COPY experimental/entrypoint.sh /usr/bin/entrypoint.sh

EXPOSE 8080
# This way, if someone sets $DOCKER_USER, docker-exec will still work as
# the uid will remain the same. note: only relevant if -u isn't passed to
# docker-run.
USER 1000
ENV USER=rocker
WORKDIR /home/rocker
ENTRYPOINT ["/usr/bin/entrypoint.sh", "--bind-addr", "0.0.0.0:8080", "."]


