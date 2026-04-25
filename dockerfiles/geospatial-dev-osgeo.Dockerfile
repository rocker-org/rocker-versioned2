FROM rocker/verse:4.6.0

ENV PROJ_VERSION="9.8.1"
ENV GDAL_VERSION="3.12.4"
ENV GEOS_VERSION="3.14.1"

COPY scripts/experimental/install_dev_osgeo.sh /rocker_scripts/experimental/install_dev_osgeo.sh
RUN /rocker_scripts/experimental/install_dev_osgeo.sh
