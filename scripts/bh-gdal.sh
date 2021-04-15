#!/bin/sh
set -eu

if [ "${GDAL_VERSION}" = "master" ]; then
    GDAL_VERSION=$(curl -Ls https://api.github.com/repos/OSGeo/gdal/commits/HEAD -H "Accept: application/vnd.github.VERSION.sha")
    export GDAL_VERSION
    GDAL_RELEASE_DATE=$(date "+%Y%m%d")
    export GDAL_RELEASE_DATE
fi

if [ -z "${GDAL_BUILD_IS_RELEASE:-}" ]; then
    export GDAL_SHA1SUM=${GDAL_VERSION}
fi

#mkdir gdal
#wget -q "https://github.com/OSGeo/gdal/archive/${GDAL_VERSION}.tar.gz" \
#    -O - | tar xz -C gdal --strip-components=1

git clone https://github.com/OSGeo/gdal
cd gdal/gdal
git checkout v${GDAL_VERSION} .
./configure --prefix=/usr \
	--without-libtool \
	--with-jpeg12 \
	--with-python \
	--with-poppler \
	--with-spatialite \
	--with-mysql \
	--with-liblzma \
	--with-webp \
	--with-epsilon \
	--with-proj="${PROJ_INSTALL_PREFIX-/usr/local}" \
	--with-poppler \
	--with-hdf5 \
	--with-dods-root=/usr \
	--with-sosi \
	--with-libtiff=internal \
	--with-geotiff=internal \
	--with-kea=/usr/bin/kea-config \
	--with-mongocxxv3 \
	--with-tiledb \
	--with-crypto

make "-j$(nproc)"
make install

cd /

rm -rf gdal
