FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu24.04

LABEL org.opencontainers.image.licenses="GPL-2.0-or-later" \
      org.opencontainers.image.source="https://github.com/rocker-org/rocker-versioned2" \
      org.opencontainers.image.vendor="Rocker Project" \
      org.opencontainers.image.authors="Carl Boettiger <cboettig@ropensci.org>"

ENV R_VERSION=devel
ENV R_HOME=/usr/local/lib/R
ENV TZ=Etc/UTC
ENV NVBLAS_CONFIG_FILE=/etc/nvblas.conf
ENV PYTHON_CONFIGURE_OPTS=--enable-shared
ENV RETICULATE_AUTOCONFIGURE=0
ENV PURGE_BUILDDEPS=false
ENV VIRTUAL_ENV=/opt/venv
ENV PATH=${PATH}:${VIRTUAL_ENV}/bin:${CUDA_HOME}/bin

COPY scripts/install_R_source.sh /rocker_scripts/install_R_source.sh

RUN /rocker_scripts/install_R_source.sh

ENV CRAN=https://cloud.r-project.org
ENV LANG=en_US.UTF-8

COPY scripts /rocker_scripts

RUN /rocker_scripts/setup_R.sh
RUN /rocker_scripts/config_R_cuda.sh
RUN /rocker_scripts/install_python.sh
