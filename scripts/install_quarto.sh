#!/bin/bash
set -e

## build ARGs
NCPUS=${NCPUS:--1}

QUARTO_VERSION=${1:-${QUARTO_VERSION:-latest}}
# Only amd64 build can be installed now
ARCH=$(dpkg --print-architecture)

if [ ! -x "$(command -v wget)" ]; then
  apt-get update
  apt-get -y install wget
fi

if [ -x "$(command -v quarto)" ]; then
  INSTALLED_QUARTO=$(quarto --version 2>/dev/null | head -n 1 | grep -oP '[\d\.]+$')
fi

if [ "$INSTALLED_QUARTO" != "$QUARTO_VERSION" ]; then

  if [ "$QUARTO_VERSION" = "latest" ]; then
    QUARTO_DL_URL=$(wget -qO- https://api.github.com/repos/quarto-dev/quarto-cli/releases/latest | grep -oP "(?<=\"browser_download_url\":\s\")https.*${ARCH}\.deb")
  else
    QUARTO_DL_URL=https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-${ARCH}.deb
  fi
  wget "${QUARTO_DL_URL}" -O quarto-"${ARCH}".deb
  dpkg -i quarto-"${ARCH}".deb
  rm quarto-"${ARCH}".deb

  quarto check install

fi

install2.r --error --skipinstalled -n "$NCPUS" \
  quarto

# Clean up
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/downloaded_packages
