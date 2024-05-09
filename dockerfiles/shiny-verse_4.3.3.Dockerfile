FROM docker.io/library/ubuntu:jammy

ENV R_VERSION="4.3.3"
ENV R_HOME="/usr/local/lib/R"
ENV TZ="Etc/UTC"

COPY scripts/install_R_source.sh /rocker_scripts/install_R_source.sh
RUN /rocker_scripts/install_R_source.sh

ENV CRAN="https://p3m.dev/cran/__linux__/jammy/2024-04-23"
ENV LANG=en_US.UTF-8

COPY scripts/bin/ /rocker_scripts/bin/
COPY scripts/setup_R.sh /rocker_scripts/setup_R.sh
RUN /rocker_scripts/setup_R.sh

COPY scripts/install_tidyverse.sh /rocker_scripts/install_tidyverse.sh
RUN /rocker_scripts/install_tidyverse.sh

ENV S6_VERSION="v2.1.0.2"
ENV SHINY_SERVER_VERSION="latest"
ENV PANDOC_VERSION="default"

COPY scripts/install_shiny_server.sh /rocker_scripts/install_shiny_server.sh
COPY scripts/install_s6init.sh /rocker_scripts/install_s6init.sh
COPY scripts/install_pandoc.sh /rocker_scripts/install_pandoc.sh
COPY scripts/init_set_env.sh /rocker_scripts/init_set_env.sh
RUN /rocker_scripts/install_shiny_server.sh

EXPOSE 3838
CMD ["/init"]

COPY scripts /rocker_scripts
