#!/bin/bash

set -e

apt-get update \
 && apt-get install -y \
    curl \
    dumb-init \
    zsh \
    htop \
    locales \
    man \
    nano \
    git \
    procps \
    openssh-client \
    sudo \
    vim.tiny \
    lsb-release \
    tmux \
  && rm -rf /var/lib/apt/lists/*

DEFAULT_USER=${1:-${DEFAULT_USER:-rocker}}
adduser --gecos '' --disabled-password ${DEFAULT_USER} && \
  echo "${DEFAULT_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd
addgroup ${DEFAULT_USER} staff

## User name is always ${DEFAULT_USER} even when run with different $(id -u):$(id -g)
## allow user name to be set with DOCKER_USER at runtime 
ARCH="$(dpkg --print-architecture)" && \
    curl -fsSL "https://github.com/boxboat/fixuid/releases/download/v0.5/fixuid-0.5-linux-$ARCH.tar.gz" | tar -C /usr/local/bin -xzf - && \
    chown root:root /usr/local/bin/fixuid && \
    chmod 4755 /usr/local/bin/fixuid && \
    mkdir -p /etc/fixuid && \
    printf "user: ${DEFAULT_USER}\ngroup: ${DEFAULT_USER}\n" > /etc/fixuid/config.yml


## Consider ability to detect latest version
VSCODE_VERSION=3.12.0

curl -fOL https://github.com/cdr/code-server/releases/download/v${VSCODE_VERSION}/code-server_${VSCODE_VERSION}_amd64.deb
dpkg -i code-server_${VSCODE_VERSION}_amd64.deb

## configure git not to request password each time
git config --system credential.helper 'cache --timeout=3600'
git config --system push.default simple



