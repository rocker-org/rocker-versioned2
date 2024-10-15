FROM rocker/verse:4.4.1

ENV PROJ_VERSION="9.5.0"
ENV GDAL_VERSION="3.9.3"
ENV GEOS_VERSION="3.13.0"

COPY scripts/experimental/install_dev_osgeo.sh /rocker_scripts/experimental/install_dev_osgeo.sh
RUN /rocker_scripts/experimental/install_dev_osgeo.sh
