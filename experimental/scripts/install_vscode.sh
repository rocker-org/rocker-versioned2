#!/bin/bash

set -e

## Consider ability to detect latest version
VSCODE_VERSION=3.12.0

curl -fOL https://github.com/cdr/code-server/releases/download/v${VSCODE_VERSION}/code-server_${VSCODE_VERSION}_amd64.deb
dpkg -i code-server_${VSCODE_VERSION}_amd64.deb

## Need to configure non-root user for RStudio
DEFAULT_USER=${1:-${DEFAULT_USER:-rocker}}
useradd -s /bin/bash -m $DEFAULT_USER
echo "${DEFAULT_USER}:${DEFAULT_USER}" | chpasswd
addgroup ${DEFAULT_USER} staff
addgroup ${DEFAULT_USER} sudo

## configure git not to request password each time
git config --system credential.helper 'cache --timeout=3600'
git config --system push.default simple



## Consider easy-to-use OAuth configurations for codeserver:
# https://www.pomerium.io/guides/code-server.html

