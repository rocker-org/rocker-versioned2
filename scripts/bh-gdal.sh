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

mkdir gdal
wget -q "https://github.com/OSGeo/gdal/archive/${GDAL_VERSION}.tar.gz" \
    -O - | tar xz -C gdal --strip-components=1


cd gdal/gdal
./configure --prefix=/usr \
	--without-libtool \
	--with-hide-internal-symbols \
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
	--with-libtiff=internal --with-rename-internal-libtiff-symbols \
	--with-geotiff=internal --with-rename-internal-libgeotiff-symbols \
	--with-kea=/usr/bin/kea-config \
	--with-mongocxxv3 \
	--with-tiledb \
	--with-crypto

make "-j$(nproc)"
make install DESTDIR="/build"



rm -rf gdal
mkdir -p /build_gdal_python/usr/lib
mkdir -p /build_gdal_python/usr/bin
mkdir -p /build_gdal_version_changing/usr/include
mv /build/usr/lib/python3            /build_gdal_python/usr/lib
mv /build/usr/lib                    /build_gdal_version_changing/usr
mv /build/usr/include/gdal_version.h /build_gdal_version_changing/usr/include
mv /build/usr/bin/*.py               /build_gdal_python/usr/bin
mv /build/usr/bin                    /build_gdal_version_changing/usr

if [ "${WITH_DEBUG_SYMBOLS}" = "yes" ]; then
    # separate debug symbols
    for P in /build_gdal_version_changing/usr/lib/* /build_gdal_python/usr/lib/python3/dist-packages/osgeo/*.so /build_gdal_version_changing/usr/bin/*; do
        if file -h "$P" | grep -qi elf; then
            F=$(basename "$P")
            mkdir -p "$(dirname "$P")/.debug"
            DEBUG_P="$(dirname "$P")/.debug/${F}.debug"
            objcopy -v --only-keep-debug --compress-debug-sections "$P" "${DEBUG_P}"
            strip --strip-debug --strip-unneeded "$P"
            objcopy --add-gnu-debuglink="${DEBUG_P}" "$P"
        fi
    done
else
    for P in /build_gdal_version_changing/usr/lib/*; do strip -s "$P" 2>/dev/null || /bin/true; done
    for P in /build_gdal_python/usr/lib/python3/dist-packages/osgeo/*.so; do strip -s "$P" 2>/dev/null || /bin/true; done
    for P in /build_gdal_version_changing/usr/bin/*; do strip -s "$P" 2>/dev/null || /bin/true; done
fi
