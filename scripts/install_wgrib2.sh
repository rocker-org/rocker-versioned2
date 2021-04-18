#!/bin/bash

## https://www.cpc.ncep.noaa.gov/products/wesley/wgrib2/

apt-get update && apt-get -y install wget
cd /opt
wget https://www.ftp.cpc.ncep.noaa.gov/wd51we/wgrib2/wgrib2.tgz
tar -xvf wgrib2.tgz
rm -rf wgrib2.tgz
cd grib2

## really someone needs to learn proper packaging conventions, but whatever
CC=gcc FC=gfortran make
ln -s /opt/grib2/wgrib2/wgrib2 /usr/local/bin/wgrib2

# Clean up
rm -rf /var/lib/apt/lists/*
