FROM rocker/verse:4.5.1

ENV PROJ_VERSION="9.6.2"
ENV GDAL_VERSION="3.11.3"
ENV GEOS_VERSION="3.13.1"

COPY scripts/experimental/install_dev_osgeo.sh /rocker_scripts/experimental/install_dev_osgeo.sh
RUN /rocker_scripts/experimental/install_dev_osgeo.sh
