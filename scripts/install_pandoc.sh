#!/bin/sh
set -e

# Note that 'default' pandoc version means the version bundled with RStudio
# if RStudio is installed , but latest otherwise

PANDOC_VERSION=${1:-${PANDOC_VERSION:-default}}

apt-get update && apt-get -y install wget

if [-x "$(command -v pandoc)" ]; then
  INSTALLED_PANDOC=$(pandoc --version 2>/dev/null | head -n 1 | grep -oP '[\d\.]+$')
fi

if [ "$INSTALLED_PANDOC" != "$PANDOC_VERSION" ]; then

  if [ -f "/usr/lib/rstudio-server/bin/pandoc/pandoc" ] &&
      { [ "$PANDOC_VERSION" = "$(/usr/lib/rstudio-server/bin/pandoc/pandoc --version | head -n 1 | grep -oP '[\d\.]+$')" ] ||
        [ "$PANDOC_VERSION" = "default" ]; }; then
    ln -s /usr/lib/rstudio-server/bin/pandoc/pandoc /usr/local/bin
    ln -s /usr/lib/rstudio-server/bin/pandoc/pandoc-citeproc /usr/local/bin
  else
    if [ "$PANDOC_VERSION" = "default" ]; then
      PANDOC_DL_URL=$(wget -qO- https://api.github.com/repos/jgm/pandoc/releases/latest | grep -oP "(?<=\"browser_download_url\":\s\")https.*amd64\.deb")
    else
      PANDOC_DL_URL=https://github.com/jgm/pandoc/releases/download/${PANDOC_VERSION}/pandoc-${PANDOC_VERSION}-amd64.deb
    fi
    wget ${PANDOC_DL_URL} -O pandoc-amd64.deb
    dpkg -i pandoc-amd64.deb
    rm pandoc-amd64.deb
  fi
  
  ## Symlink pandoc & standard pandoc templates for use system-wide
  PANDOC_TEMPLATES_VERSION=`pandoc -v | grep -oP "(?<=pandoc\s)[0-9\.]+$"`
  wget https://github.com/jgm/pandoc-templates/archive/${PANDOC_TEMPLATES_VERSION}.tar.gz -O pandoc-templates.tar.gz
  mkdir -p /opt/pandoc/templates
  tar xvf pandoc-templates.tar.gz
  cp -r pandoc-templates*/* /opt/pandoc/templates && rm -rf pandoc-templates* 
  mkdir /root/.pandoc && ln -s /opt/pandoc/templates /root/.pandoc/templates
  
fi
