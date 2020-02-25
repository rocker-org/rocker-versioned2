echo 'selected_scheme scheme-minimal
TEXDIR /usr/local/texlive
TEXMFCONFIG ~/.texlive/texmf-config
TEXMFHOME ~/texmf
TEXMFLOCAL /usr/local/texlive/texmf-local
TEXMFSYSCONFIG /usr/local/texlive/texmf-config
TEXMFSYSVAR /usr/local/texlive/texmf-var
TEXMFVAR ~/.texlive/texmf-var
option_doc 0
option_src 0' > /tmp/texlive-profile.txt

# set up packages
apt-get update && apt-get -y install wget perl xzdec 
wget http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz 
tar -xzf install-tl-unx.tar.gz 
install-tl-20*/install-tl --profile=/tmp/texlive-profile.txt && \
    rm -rf install-tl-*

# ENV PATH=/usr/local/texlive/bin/x86_64-linux:$PATH

tlmgr update --self


