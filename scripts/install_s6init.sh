#!/bin/sh
set -e

### Sets up S6 supervisor.

S6_VERSION=${1:-${S6_VERSION:-v1.21.7.0}}
S6_BEHAVIOUR_IF_STAGE2_FAILS=2

## Set up S6 init system
if [ -f "/rocker_scripts/.s6_version" ] && [ "$S6_VERSION" = "$(cat /rocker_scripts/.s6_version)" ]; then
  echo "S6 already installed"
else
  wget -P /tmp/ https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/s6-overlay-amd64.tar.gz
  tar xzf /tmp/s6-overlay-amd64.tar.gz -C /
  echo "S6_VERSION" > /rocker_scripts/.s6_version
fi

