FROM docker.io/library/ubuntu:jammy

ENV R_VERSION="4.2.3"
ENV R_HOME="/usr/local/lib/R"
ENV TZ="Etc/UTC"

COPY scripts/install_R_source.sh /rocker_scripts/install_R_source.sh
RUN /rocker_scripts/install_R_source.sh

ENV CRAN="https://p3m.dev/cran/__linux__/jammy/2023-04-20"

COPY scripts/setup_R.sh /rocker_scripts/setup_R.sh
RUN /rocker_scripts/setup_R.sh

CMD ["R"]

COPY scripts /rocker_scripts
