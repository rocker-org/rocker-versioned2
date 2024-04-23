FROM docker.io/library/ubuntu:latest

ENV R_VERSION="devel"
ENV R_HOME="/usr/local/lib/R"
ENV TZ="Etc/UTC"

COPY scripts/install_R_source.sh /rocker_scripts/install_R_source.sh
RUN /rocker_scripts/install_R_source.sh

ENV CRAN="https://cloud.r-project.org"

COPY scripts/bin/ /rocker_scripts/bin/
COPY scripts/setup_R.sh /rocker_scripts/setup_R.sh
RUN /rocker_scripts/setup_R.sh

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

ENV CTAN_REPO="https://mirror.ctan.org/systems/texlive/tlnet"
ENV PATH="$PATH:/usr/local/texlive/bin/linux"

COPY scripts/install_texlive.sh /rocker_scripts/install_texlive.sh
RUN /rocker_scripts/install_verse.sh

COPY scripts/install_geospatial.sh /rocker_scripts/install_geospatial.sh
RUN /rocker_scripts/install_geospatial.sh

COPY scripts /rocker_scripts
