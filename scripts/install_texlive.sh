#!/bin/bash
set -e

# Install TeX Live via Debian/Ubuntu apt packages.
# This provides arm64 support, security updates via apt, and simpler
# maintenance compared to the upstream CTAN installer + tlmgr approach.
# Trade-off: versions lag CTAN by ~6-12 months; install additional
# texlive-* packages via apt for any missing CTAN packages.

if dpkg -l texlive-latex-base 2>/dev/null | grep -q "^ii"; then
    echo "texlive already installed"
    exit 0
fi

export DEBIAN_FRONTEND=noninteractive

# a function to install apt packages only if they are not installed
function apt_install() {
    if ! dpkg -s "$@" >/dev/null 2>&1; then
        if [ "$(find /var/lib/apt/lists/* 2>/dev/null | wc -l)" = "0" ]; then
            apt-get update
        fi
        apt-get install -y --no-install-recommends "$@"
    fi
}

apt_install \
    lmodern \
    texlive-fonts-recommended \
    texlive-latex-base \
    texlive-latex-extra \
    texlive-latex-recommended \
    texlive-luatex \
    texlive-xetex

rm -rf /var/lib/apt/lists/*

echo "texlive installed via apt. pdflatex: $(pdflatex --version | head -1)"
