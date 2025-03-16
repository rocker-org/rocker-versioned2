FROM rocker/verse:4.4.3

ENV PROJ_VERSION="9.6.0"
ENV GDAL_VERSION="3.10.2"
ENV GEOS_VERSION="3.13.1"

COPY scripts/experimental/install_dev_osgeo.sh /rocker_scripts/experimental/install_dev_osgeo.sh
RUN /rocker_scripts/experimental/install_dev_osgeo.sh
