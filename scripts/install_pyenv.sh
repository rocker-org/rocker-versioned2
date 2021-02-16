#!/bin/bash

## Install pyenv, to facilitate installation of different python versions
## Allows users to do things like:
##     pyenv install 3.7.9 # install python 3.7.9; e.g. for tensorflow 1.15.x
##     pyenv global 3.7.9  # activate as the default python 
## 

set -e

apt-get update && apt-get -y install curl python3-pip
pip install --upgrade --ignore-installed pipenv 


# consider a version-stable alternative for the installer?
curl https://pyenv.run | bash
mv /root/.pyenv /opt/pyenv

# pipenv requires ~/.local/bin to be on the path...
echo 'PATH="/opt/pyenv/bin:~/.local/bin:$PATH"' >> ${R_HOME}/etc/Renviron
echo 'PATH="/opt/pyenv/bin:~/.local/bin:$PATH"' >> /etc/bash.bashrc
echo 'eval "$(pyenv init -)"' >>  /etc/bash.bashrc
echo 'eval "$(pyenv virtualenv-init -)"' >> /etc/bash.bashrc




