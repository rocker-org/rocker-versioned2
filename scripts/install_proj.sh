#!/bin/sh
set -eu

git clone https://github.com/OSGeo/PROJ

PROJ_INSTALL_PREFIX=${PROJ_INSTALL_PREFIX:-/usr/local}
PROJ_VERSION=${PROJ_VERSION:-master} 
cd PROJ

git checkout ${PROJ_VERSION}
./autogen.sh
./configure
#CXXFLAGS="-DPROJ_RENAME_SYMBOLS -O2" CFLAGS=$CXXFLAGS ./configure --prefix=${PROJ_INSTALL_PREFIX} --disable-static
make
make install

#cd ${PROJ_INSTALL_PREFIX}/lib
## Rename the library to libinternalproj
#mv libproj.so.19.2.0 libinternalproj.so.19.2.0
#ln -s libinternalproj.so.19.2.0 libinternalproj.so.19
#ln -s libinternalproj.so.19.2.0 libinternalproj.so
#rm -f libproj.*
## Install the patchelf package
#apt-get update && apt-get -y install patchelf
#patchelf --set-soname libinternalproj.so libinternalproj.so

