#!/bin/bash
set -e

# Remove spaces
remove_spaces() {
    local var="$*"
    # Remove all spaces
    var=${var//$' '/''}
    echo -e "$var"
    return 0
}

function create_user() {
  local username=$1
  local password=$2

  echo "Processing user '${username}'."

  if id -u "$username" >/dev/null 2>&1; then
    echo "'${username}' user already exists. Nothing else to do."
  else
    useradd -s /bin/bash -m $username
    # invalid user name
    if [ "$?" == 3 ]; then
      echo "Failed to create user '${username}'."
      return
    fi

    if [ -z "$password" ]; then
      echo "Password not provided. Setting it equals to username."
      password=${username}
    fi
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

  echo "Done with user '${username}'."
}

if [ -n "$BATCH_USER_CREATION" ]; then
  echo "Requested creation of multiple user accounts in batch mode."

  BATCH_USER_CREATION=`remove_spaces "$BATCH_USER_CREATION"`

  for user in $(echo $BATCH_USER_CREATION | tr ';' ' '); do
    IFS=: read username password <<< $(echo $user)

    if [ -z "$username" ]; then
      echo "Failed to create user: username undefined"
      continue;
    else
      create_user $username $password || true
    fi
  done
  echo "Finished creation of multiple user accounts in batch mode."
fi
