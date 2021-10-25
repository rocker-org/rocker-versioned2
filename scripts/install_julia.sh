#!/bin/bash
set -e

## build ARGs
NCPUS=${NCPUS:--1}

JULIA_VERSION=${1:-${JULIA_VERSION:-latest}}

ARCH_LONG=$(uname -p)
ARCH_SHORT=$ARCH_LONG

if [ "$ARCH_LONG" = "x86_64" ]; then
  ARCH_SHORT="x64"
fi

if [ ! -x "$(command -v wget)" ]; then
  apt-get update
  apt-get -y install wget
fi

install2.r --error --skipinstalled -n "$NCPUS" \
  yaml \
  JuliaCall \
  JuliaConnectoR

# Get the latest Julia version by using R and the R yaml package.
if [ "$JULIA_VERSION" = "latest" ]; then
  JULIA_VERSION=$(Rscript -e '
js <- yaml::read_yaml("https://julialang-s3.julialang.org/bin/versions.json")
versions <- names(js)
is_stable <- unlist(Map(function(x) x$stable, js))
latest_version <- sort(versions[is_stable], decreasing = TRUE)[1]
cat(latest_version)
')
fi

JULIA_MINOR_VERSION=${JULIA_VERSION:0:3}

# Download Julia and create a symbolic link.
wget "https://julialang-s3.julialang.org/bin/linux/${ARCH_SHORT}/${JULIA_MINOR_VERSION}/julia-${JULIA_VERSION}-linux-${ARCH_LONG}.tar.gz"
mkdir /opt/julia
tar zxvf "julia-${JULIA_VERSION}-linux-${ARCH_LONG}.tar.gz" -C /opt/julia --strip-components 1
rm -f "julia-${JULIA_VERSION}-linux-${ARCH_LONG}.tar.gz"
ln -s /opt/julia/bin/julia /usr/local/bin/julia

julia --version

# Clean up
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/downloaded_packages
