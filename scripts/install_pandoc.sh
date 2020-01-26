#!/bin/sh
set -e

if [ -z "$1" ] && [ -z "$PANDOC_VERSION" ]; then
  PANDOC_VERSION="default";
elif [ $# = 1 ]; then
  PANDOC_VERSION=$1;
fi

if [ -f "/usr/lib/rstudio-server/bin/pandoc/pandoc" ] &&
    { [ "$PANDOC_VERSION" = "$(/usr/lib/rstudio-server/bin/pandoc/pandoc --version | head -n 1 | grep -oP '[\d\.]+$')" ] ||
      [ "$PANDOC_VERSION" = "default" ]; }; then
  ln -s /usr/lib/rstudio-server/bin/pandoc/pandoc /usr/local/bin
  ln -s /usr/lib/rstudio-server/bin/pandoc/pandoc-citeproc /usr/local/bin
else
  if [ "$PANDOC_VERSION" = "default" ]; then
    PANDOC_VERSION=$(curl -s https://api.github.com/repos/jgm/pandoc/releases/latest | grep -oP "(?<=\"tag_name\":\s\")[0-9\.]+")
  fi
  wget https://github.com/jgm/pandoc/releases/download/${PANDOC_VERSION}/pandoc-${PANDOC_VERSION}-amd64.deb
  dpkg -i pandoc-${PANDOC_VERSION}-amd64.deb
  rm pandoc-${PANDOC_VERSION}-amd64.deb
fi

## Symlink pandoc & standard pandoc templates for use system-wide
PANDOC_TEMPLATES_VERSION=`pandoc -v | grep -oP "(?<=pandoc\s)[0-9\.]+$"`
git clone --recursive --branch ${PANDOC_TEMPLATES_VERSION} https://github.com/jgm/pandoc-templates
mkdir -p /opt/pandoc/templates
cp -r pandoc-templates*/* /opt/pandoc/templates && rm -rf pandoc-templates*
mkdir /root/.pandoc && ln -s /opt/pandoc/templates /root/.pandoc/templates
