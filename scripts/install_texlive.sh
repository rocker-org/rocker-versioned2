#!/bin/bash

echo 'selected_scheme scheme-infraonly
TEXDIR /usr/local/texlive
TEXMFCONFIG /opt/texlive/texmf-config
TEXMFHOME  /opt/texlive/texmf
TEXMFLOCAL /opt/texlive/texmf-local
TEXMFSYSCONFIG /opt/texlive/texmf-config
TEXMFSYSVAR /opt/texlive/texmf-var
TEXMFVAR /opt/texlive/texmf-var
option_doc 0
option_src 0' > /tmp/texlive-profile.txt

CTAN_REPO=${CTAN_REPO:-https://mirror.ctan.org/systems/texlive/tlnet}
export PATH=$PATH:/usr/local/texlive/bin/x86_64-linux/:/usr/local/texlive/bin/aarch64-linux/

mkdir -p /opt/texlive
# set up packages
apt-get update && apt-get -y install wget perl xzdec
wget ${CTAN_REPO}/install-tl-unx.tar.gz
tar -xzf install-tl-unx.tar.gz
install-tl-20*/install-tl --profile=/tmp/texlive-profile.txt --repository $CTAN_REPO && \
    rm -rf install-tl-*

tlmgr update --self
tlmgr install latex-bin luatex xetex
tlmgr install ae bibtex context inconsolata listings makeindex metafont mfware parskip pdfcrop tex tools url xkeyval

## do not add to /usr/local/bin
# tlmgr path add
# instead, we keep binaries separate and add to PATH
echo "PATH=${PATH}" >> ${R_HOME}/etc/Renviron.site

## open permissions to avoid needless warnings
NON_ROOT_USER=$(getent passwd "1000" | cut -d: -f1)
if [ -n "$NON_ROOT_USER" ]; then
    chown -R ${NON_ROOT_USER}:staff /opt/texlive
    chown -R ${NON_ROOT_USER}:staff /usr/local/texlive
fi
chmod -R 777 /opt/texlive
chmod -R 777 /usr/local/texlive
