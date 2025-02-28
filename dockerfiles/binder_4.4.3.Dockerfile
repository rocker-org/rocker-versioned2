FROM rocker/geospatial:4.4.3

ENV NB_USER="rstudio"
ENV VIRTUAL_ENV="/opt/venv"
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}"

COPY scripts/install_jupyter.sh /rocker_scripts/install_jupyter.sh
RUN /rocker_scripts/install_jupyter.sh

EXPOSE 8888

CMD ["jupyter", "lab", "--ip", "0.0.0.0", "--no-browser"]

USER ${NB_USER}

WORKDIR /home/${NB_USER}
