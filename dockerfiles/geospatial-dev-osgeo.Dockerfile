FROM rocker/verse:4.6.1

ENV PROJ_VERSION="9.9.0"
ENV GDAL_VERSION="3.13.3"
ENV GEOS_VERSION="3.15.0"

COPY scripts/experimental/install_dev_osgeo.sh /rocker_scripts/experimental/install_dev_osgeo.sh
RUN /rocker_scripts/experimental/install_dev_osgeo.sh
