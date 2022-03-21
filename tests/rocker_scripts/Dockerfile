ARG tag=latest
FROM rocker/r-ver:${tag}

COPY scripts /rocker_scripts
COPY tests/rocker_scripts/test.sh /test.sh

ARG rstudio=skip
RUN /test.sh install_rstudio.sh $rstudio

ARG pandoc=skip
RUN /test.sh install_pandoc.sh $pandoc

ARG tidyverse=skip
RUN /test.sh install_tidyverse.sh $tidyverse

ARG verse=skip
RUN /test.sh install_verse.sh $verse
