FROM rocker/cuda:4.3.2

ENV S6_VERSION=v2.1.0.2
ENV RSTUDIO_VERSION=2023.12.0+369
ENV DEFAULT_USER=rstudio
ENV PANDOC_VERSION=default
ENV QUARTO_VERSION=default
ENV PATH=${VIRTUAL_ENV}/bin:${PATH}

RUN /rocker_scripts/install_rstudio.sh
RUN /rocker_scripts/install_pandoc.sh
RUN /rocker_scripts/install_quarto.sh
RUN /rocker_scripts/install_tidyverse.sh

EXPOSE 8787

CMD ["/init"]
