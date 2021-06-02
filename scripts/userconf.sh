#!/usr/bin/with-contenv bash

## Set defaults for environmental variables in case they are undefined
USER=${USER:=rstudio}
PASSWORD=${PASSWORD:=rstudio}
USERID=${USERID:=1000}
GROUPID=${GROUPID:=1000}
ROOT=${ROOT:=FALSE}
UMASK=${UMASK:=022}
LANG=${LANG:="en_US.UTF-8 UTF-8"}
TZ=${TZ:="Etc/UTC"}

## Make sure RStudio inherits the full path
echo "PATH=${PATH}" >> ${R_HOME}/etc/Renviron

bold=$(tput bold)
normal=$(tput sgr0)

if [[ ${DISABLE_AUTH,,} == "true" ]]

then
	mv /etc/rstudio/disable_auth_rserver.conf /etc/rstudio/rserver.conf
	echo "USER=$USER" >> /etc/environment
fi

if grep --quiet "auth-none=1" /etc/rstudio/rserver.conf
then
	echo "Skipping authentication as requested"
elif [ "$PASSWORD" == "rstudio" ]
then
    printf "\n\n"
    tput bold
    printf "\e[31mERROR\e[39m: You must set a unique PASSWORD (not 'rstudio') first! e.g. run with:\n"
    printf "docker run -e PASSWORD=\e[92m<YOUR_PASS>\e[39m -p 8787:8787 rocker/rstudio\n"
    tput sgr0
    printf "\n\n"
    exit 1
fi

if [ "$USERID" -lt 1000 ]
# Probably a macOS user, https://github.com/rocker-org/rocker/issues/205
  then
    echo "$USERID is less than 1000"
    check_user_id=$(grep -F "auth-minimum-user-id" /etc/rstudio/rserver.conf)
    if [[ ! -z $check_user_id ]]
    then
      echo "minumum authorised user already exists in /etc/rstudio/rserver.conf: $check_user_id"
    else
      echo "setting minumum authorised user to 499"
      echo auth-minimum-user-id=499 >> /etc/rstudio/rserver.conf
    fi
fi

if [ "$USERID" -ne 1000 ]
## Configure user with a different USERID if requested.
  then
    echo "deleting user rstudio"
    userdel rstudio
    echo "creating new $USER with UID $USERID"
    useradd -m $USER -u $USERID
    mkdir -p /home/$USER
    chown -R $USER /home/$USER
    usermod -a -G staff $USER
elif [ "$USER" != "rstudio" ]
  then
    ## cannot move home folder when it's a shared volume, have to copy and change permissions instead
    cp -r /home/rstudio /home/$USER
    ## RENAME the user
    usermod -l $USER -d /home/$USER rstudio
    groupmod -n $USER rstudio
    usermod -a -G staff $USER
    chown -R $USER:$USER /home/$USER
    echo "USER is now $USER"
fi

if [ "$GROUPID" -ne 1000 ]
## Configure the primary GID (whether rstudio or $USER) with a different GROUPID if requested.
  then
    echo "Modifying primary group $(id $USER -g -n)"
    groupmod -g $GROUPID $(id $USER -g -n)
    echo "Primary group ID is now custom_group $GROUPID"
fi

## Add a password to user
echo "$USER:$PASSWORD" | chpasswd

# Use Env flag to know if user should be added to sudoers
if [[ ${ROOT,,} == "true" ]]
  then
    adduser $USER sudo && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
    echo "$USER added to sudoers"
fi

## Change Umask value if desired
if [ "$UMASK" -ne 022 ]
  then
    echo "server-set-umask=false" >> /etc/rstudio/rserver.conf
    echo "Sys.umask(mode=$UMASK)" >> /home/$USER/.Rprofile
fi

## Update Locale if needed
if [ "$LANG" -ne  "en_US.UTF-8 UTF-8" ]
  then
    echo "$LANG" >> /etc/locale.gen
    locale-gen $LANG
    /usr/sbin/update-locale LANG=$LANG
    ## We have to set them after generating the locale
    LANGUAGE=${LANG}
    LC_ALL=${LANG}
fi

## Next one for timezone setup
if [ "$TZ" -ne  "Etc/UTC" ]
  then
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
fi

## add these to the global environment so they are available to the RStudio user
echo "HTTR_LOCALHOST=$HTTR_LOCALHOST" >> /etc/environment
echo "HTTR_PORT=$HTTR_PORT" >> /etc/R/environment
## Set our dynamic variables in Rprofile.site to be reflected by RStudio
## TODO: This should be a dynamic script so that all env vars in /etc/environment
##       will be added as env var to the RStudio environment.
##       The next line is just a demo how it could look like
echo "Sys.setenv('HTTR_LOCALHOST'='$HTTR_LOCALHOST')
Sys.setenv('HTTR_PORT'='$HTTR_PORT')" >> ${R_HOME}/etc/Rprofile.site
