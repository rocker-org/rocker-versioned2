echo 'selected_scheme scheme-infraonly
TEXDIR /opt/texlive
TEXMFCONFIG /opt/texlive/texmf-config
TEXMFHOME  /opt/texlive/texmf
TEXMFLOCAL /opt/texlive/texmf-local
TEXMFSYSCONFIG /opt/texlive/texmf-config
TEXMFSYSVAR /opt/texlive/texmf-var
TEXMFVAR /opt/texlive/texmf-var
option_doc 0
option_src 0' > /tmp/texlive-profile.txt

mkdir -p /opt/texlive
# set up packages
apt-get update && apt-get -y install wget perl xzdec 
wget http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz 
tar -xzf install-tl-unx.tar.gz 
install-tl-20*/install-tl --profile=/tmp/texlive-profile.txt && \
    rm -rf install-tl-*

# ENV PATH=/opt/texlive/bin/x86_64-linux:$PATH

tlmgr update --self
tlmgr install latex-bin luatex xetex

chown -R root:staff /opt/texlive
chmod -R g+w /opt/texlive
chmod -R g+wx /opt/texlive/bin

