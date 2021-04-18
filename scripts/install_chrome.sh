#!/bin/bash
set -e

# install Google Chrome instead of Chromium because Chromium is only available as a Snap package
curl -LO https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb

apt-get update && apt-get install -y --no-install-recommends \
        ./google-chrome-stable_current_amd64.deb

rm google-chrome-stable_current_amd64.deb
