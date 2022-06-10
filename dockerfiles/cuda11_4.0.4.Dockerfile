FROM rocker/r-ver:4.0.4

LABEL org.opencontainers.image.licenses="GPL-2.0-or-later" \
      org.opencontainers.image.source="https://github.com/rocker-org/rocker-versioned2" \
      org.opencontainers.image.vendor="Rocker Project" \
      org.opencontainers.image.authors="Carl Boettiger <cboettig@ropensci.org>"

ENV CUDA_VERSION=11.1
ENV NCCL_VERSION=2.7.8
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility
ENV NVIDIA_REQUIRE_CUDA=cuda>=11.1 brand=tesla,driver>=418,driver<419 brand=tesla,driver>=440,driver<441 brand=tesla,driver>=450,driver<451
ENV CUDA_HOME=/usr/local/cuda
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CUDA_HOME/lib64:$CUDA_HOME/extras/CUPTI/lib64:$CUDA_HOME/lib64/libnvblas.so:
ENV LIBRARY_PATH=/usr/local/cuda/lib64/stubs
ENV NVBLAS_CONFIG_FILE=/etc/nvblas.conf
ENV WORKON_HOME=/opt/venv
ENV PYTHON_VENV_PATH=/opt/venv/reticulate
ENV PYTHON_CONFIGURE_OPTS=--enable-shared
ENV RETICULATE_MINICONDA_ENABLED=FALSE
ENV PATH=${PYTHON_VENV_PATH}/bin:${CUDA_HOME}/bin:/usr/local/nviida/bin:${PATH}:/usr/local/texlive/bin/linux

RUN /rocker_scripts/install_cuda-11.1.sh
RUN /rocker_scripts/config_R_cuda.sh
RUN /rocker_scripts/install_python.sh
