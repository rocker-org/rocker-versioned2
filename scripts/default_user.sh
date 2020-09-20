#!/bin/bash


if id -u "$user" >/dev/null 2>&1; then
    echo 'rstudio user already exists'
else
  ## Need to configure non-root user for RStudio
  DEFAULT_USER=${1:-${DEFAULT_USER:-rstudio}}
  useradd $DEFAULT_USER
  echo "${DEFAULT_USER}:${DEFAULT_USER}" | chpasswd
  mkdir -p /home/${DEFAULT_USER}
  chown ${DEFAULT_USER}:${DEFAULT_USER} /home/${DEFAULT_USER}
  addgroup ${DEFAULT_USER} staff
  
  mkdir -p /home/${DEFAULT_USER}/.rstudio/monitored/user-settings
  echo "alwaysSaveHistory='0' \
      \nloadRData='0' \
      \nsaveAction='0'" \
      > /home/${DEFAULT_USER}/.rstudio/monitored/user-settings/user-settings
  
  chown -R ${DEFAULT_USER}:${DEFAULT_USER} /home/${DEFAULT_USER}
  
fi

# If shiny server installed, make the user part of the shiny group
if [ -x "$(command -v shiny-server)" ]; then
  adduser ${DEFAULT_USER} shiny
fi

## configure git not to request password each time
git config --system credential.helper 'cache --timeout=3600'
git config --system push.default simple


