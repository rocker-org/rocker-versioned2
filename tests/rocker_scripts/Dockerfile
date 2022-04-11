ARG tag=latest
FROM rocker/r-ver:${tag}

COPY tests/rocker_scripts/test.sh /test.sh
COPY scripts /rocker_scripts

ARG script_name=install_rstudio.sh
ARG script_arg=skip
RUN /test.sh ${script_name} ${script_arg}
