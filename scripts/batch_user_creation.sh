#!/bin/bash
set -e

function create_user() {
  local username=$1
  local password=$2
  if id -u "$username" >/dev/null 2>&1; then
    echo '$username user already exists'
  else
    useradd -s /bin/bash -m $username
    echo "${username}:${password}" | chpasswd
    addgroup ${username} staff

    mkdir -p /home/${username}/.rstudio/monitored/user-settings
    echo "alwaysSaveHistory='0' \
        \nloadRData='0' \
        \nsaveAction='0'" \
        > /home/${username}/.rstudio/monitored/user-settings/user-settings

    chown -R "${username}:${username}" "/home/${username}"
    # Prevent other users, but the owner, from accessing a home directory
    chmod 0700 "/home/${username}"
  fi

  # If shiny server installed, make the user part of the shiny group
  if [ -x "$(command -v shiny-server)" ]; then
    adduser ${username} shiny
  fi
}

if [ -n "$BATCH_USER_CREATION" ]; then
  echo "Requested creation of multiple user accounts in batch mode."

  for user in $(echo $BATCH_USER_CREATION | tr ';' ' '); do
    IFS=: read username password <<< $(echo $user)
    create_user $username $password
  done
  echo "Finished creation of multiple user accounts in batch mode."

  # For security reasons...
  unset BATCH_USER_CREATION
fi
