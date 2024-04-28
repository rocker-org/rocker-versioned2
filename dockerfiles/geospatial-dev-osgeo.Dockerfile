FROM rocker/verse:4.4.0

ENV PROJ_VERSION="9.4.0"
ENV GDAL_VERSION="3.8.5"
ENV GEOS_VERSION="3.12.1"

COPY scripts/experimental/install_dev_osgeo.sh /rocker_scripts/experimental/install_dev_osgeo.sh
RUN /rocker_scripts/experimental/install_dev_osgeo.sh
