FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

ENV R_VERSION="4.3.3"
ENV R_HOME="/usr/local/lib/R"
ENV TZ="Etc/UTC"

COPY scripts/install_R_source.sh /rocker_scripts/install_R_source.sh
RUN /rocker_scripts/install_R_source.sh

ENV CRAN="https://p3m.dev/cran/__linux__/jammy/latest"

COPY scripts/setup_R.sh /rocker_scripts/setup_R.sh
RUN /rocker_scripts/setup_R.sh

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

COPY scripts/install_tidyverse.sh /rocker_scripts/install_tidyverse.sh
RUN /rocker_scripts/install_tidyverse.sh

ENV S6_VERSION="v2.1.0.2"
ENV RSTUDIO_VERSION="2023.12.0+369"
ENV DEFAULT_USER="rstudio"

COPY scripts/install_rstudio.sh /rocker_scripts/install_rstudio.sh
RUN /rocker_scripts/install_rstudio.sh

EXPOSE 8787
CMD ["/init"]

COPY scripts/install_pandoc.sh /rocker_scripts/install_pandoc.sh
RUN /rocker_scripts/install_pandoc.sh

COPY scripts/install_quarto.sh /rocker_scripts/install_quarto.sh
RUN /rocker_scripts/install_quarto.sh

COPY scripts /rocker_scripts
