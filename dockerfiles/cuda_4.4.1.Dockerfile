# syntax=docker/dockerfile:1

FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

ENV R_VERSION="4.4.1"
ENV R_HOME="/usr/local/lib/R"
ENV TZ="Etc/UTC"

COPY scripts/install_R_source.sh /rocker_scripts/install_R_source.sh
RUN /rocker_scripts/install_R_source.sh

ENV CRAN="https://p3m.dev/cran/__linux__/jammy/2024-10-30"
ENV LANG=en_US.UTF-8

COPY scripts/bin/ /rocker_scripts/bin/
COPY scripts/setup_R.sh /rocker_scripts/setup_R.sh
RUN <<EOF
if grep -q "1000" /etc/passwd; then
    userdel --remove "$(id -un 1000)";
fi
/rocker_scripts/setup_R.sh
EOF

CMD ["R"]

ENV NVBLAS_CONFIG_FILE="/etc/nvblas.conf"

COPY scripts/config_R_cuda.sh /rocker_scripts/config_R_cuda.sh
RUN /rocker_scripts/config_R_cuda.sh

ENV PYTHON_CONFIGURE_OPTS="--enable-shared"
ENV RETICULATE_AUTOCONFIGURE="0"
ENV PURGE_BUILDDEPS="false"
ENV VIRTUAL_ENV="/opt/venv"
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}:${CUDA_HOME}/bin"

COPY scripts/install_python.sh /rocker_scripts/install_python.sh
RUN /rocker_scripts/install_python.sh

COPY scripts /rocker_scripts
