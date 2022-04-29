#!/bin/bash
set -eu

git clone https://github.com/OSGeo/PROJ

PROJ_VERSION=${PROJ_VERSION:-master}
cd PROJ

git checkout ${PROJ_VERSION} .
./autogen.sh
./configure --prefix=/usr/local
make
make install

