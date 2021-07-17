#!/bin/bash

## https://www.cpc.ncep.noaa.gov/products/wesley/wgrib2/

apt-get update && apt-get -y install wget
cd /opt
wget https://www.ftp.cpc.ncep.noaa.gov/wd51we/wgrib2/wgrib2.tgz
tar -xvf wgrib2.tgz
rm -rf wgrib2.tgz
cd grib2

## arm64: need to rewrite the makefile to compile wgrib2 to use NetCDF4, but it is not supported in 8/2020.
## https://www.cpc.ncep.noaa.gov/products/wesley/wgrib2/index.html
## set USE_NETCDF4=1, USE_JASPER=0
# if [ $(dpkg --print-architecture) = "arm64" ]; then
#     sed -i -e 's/^USE_NETCDF4=0/USE_NETCDF4=1/' makefile
#     sed -i -e 's/^USE_NETCDF3=1/USE_NETCDF3=0/' makefile
#     sed -i -e 's/^USE_JASPER=1/USE_JASPER=0/' makefile
# fi

## really someone needs to learn proper packaging conventions, but whatever
CC=gcc FC=gfortran make
ln -s /opt/grib2/wgrib2/wgrib2 /usr/local/bin/wgrib2

# Clean up
rm -rf /var/lib/apt/lists/*
