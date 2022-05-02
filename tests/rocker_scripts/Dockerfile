ARG base_image="rocker/r-ver"
ARG tag="latest"
FROM ${base_image}:${tag}

COPY tests/rocker_scripts/test.sh /test.sh
COPY scripts /rocker_scripts

ARG script_name=install_rstudio.sh
ARG script_arg=skip
RUN /test.sh ${script_name} ${script_arg}
