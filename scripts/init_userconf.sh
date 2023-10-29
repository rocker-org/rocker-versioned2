#!/usr/bin/with-contenv bash
# shellcheck shell=bash

## Set defaults for environmental variables in case they are undefined
DEFAULT_USER=${DEFAULT_USER:-rstudio}
USER=${USER:=${DEFAULT_USER}}
USERID=${USERID:=1000}
GROUPID=${GROUPID:=1000}
ROOT=${ROOT:=FALSE}
UMASK=${UMASK:=022}
LANG=${LANG:=en_US.UTF-8}
TZ=${TZ:=Etc/UTC}
RUNROOTLESS=${RUNROOTLESS:=auto}

if [ "${RUNROOTLESS}" = "auto" ]; then
    RUNROOTLESS=$(grep 4294967295 /proc/self/uid_map >/dev/null && echo "false" || echo "true")
fi

USERHOME="/home/${USER}"

if [ "${RUNROOTLESS}" = "true" ]; then
    printf "Assuming the container runs under rootless mode\n"
    printf "Under rootless mode,\n"
    printf " - You will log in using 'root' as user\n"
    printf " - You will have root privileges within the container (e.g. apt)\n"
    printf " - The files you create as root on mounted volumes will appear at the host as owned by the user who started the container\n"
    printf " - You can't modify host files you don't have permission to\n"
    printf " - You should NOT run in RUNROOTLESS=true if you are using the container with privileges (e.g. sudo docker run... or sudo podman run...)\n"
    # The container was started asking to login as the root user.
    # This is a good approach when running docker or podman rootless
    # https://docs.docker.com/engine/security/rootless/
    #
    # When running docker rootless or podman rootless, the root user in
    # the container has the capabilities of the actual host user. Nothing else.
    #
    # All files modified inside the container by the root user that are mapped
    # to the host will appear in the host as modified by the user who runs the
    # container. However from inside the container they appear to be modified by
    # root.
    #
    # So, the user can run apt-get as the root user inside the container. No
    # need for handling sudoers, since to the container the user is root.
    #
    # Higher user ids in the container (e.g. 1000) get mapped to very high user
    # ids at the host. We don't need that and it just confuses things
    USER="root"
    USERID=0
    GROUPID=0
    USERHOME="/root"

    # Keep all groups that have been set:
    # When running rootless podman, podman may set the groups of the host user
    # to the process running in the container with the option
    # podman run --group-add keep-groups
    #
    # This option has the caveat that the GIDs which have not been mapped to
    # the container in the namespace will appear as the overflow_gid (65534).
    #
    # While this process has the GID assigned (and therefore it has the
    # privileges granted by that GID, this process cannot internally refer
    # to that GID, because it is not mapped, and it appears as nobody/nogroup.
    #
    # This lack of mapping becomes a problem when we need to be able
    # to assign those same groups to the processes created when a user logs
    # in through the web interface. There, we are not able to setgroups() as
    # podman did when the initial process in the container was started.
    #
    # What can we do?
    # A solution goes through a sysadmin in the host allowing users to
    # impersonate the target GID in /etc/subgid.
    #
    # For instance, if you have a "university_data" group, that has GID 2000
    # and you have PhD students "alice" and "bob" who are in that group, you will
    # need to have an additional entry in /etc/subgid for each of them:
    # alice:2000:1
    # bob:2000:1
    #
    # That entry reads as
    # > Grant {alice/bob} the ability to become GID 2000.
    #
    # Those entries should be **additional** to the already existing entries that
    # grant a big number of unused GIDs.
    #
    # Then use `podman system migrate` to refresh podman configuration.
    #
    # Podman will then be able to see those groups, although unfortunately
    # the group name in the container will not be "university_data" but it will
    # instead look like "adm" or "sys" or "bin".
    #
    # I'm trying to suggest an improvement to podman to address this a bit better
    # at:
    # https://github.com/containers/podman/issues/18333
    #
    ROOT_IN_GROUPS="$(id -G)"
    OVERFLOWGID=$(cat "/proc/sys/kernel/overflowgid")
    for g in ${ROOT_IN_GROUPS}; do
        if [ "$g" -eq 0 ] || [ "$g" -eq "${OVERFLOWGID}" ]; then
            # 0 is already our GID
            # 65534 is nogroup (the overflow_gid)
            continue
        fi
        usermod -aG "$g" "${USER}"
    done
fi

if [[ ${DISABLE_AUTH,,} == "true" ]]; then
    cp /etc/rstudio/disable_auth_rserver.conf /etc/rstudio/rserver.conf
    echo "USER=$USER" >>/etc/environment
fi

if grep --quiet "auth-none=1" /etc/rstudio/rserver.conf; then
    echo "Skipping authentication as requested"
elif [ -z "$PASSWORD" ]; then
    PASSWORD=$(pwgen 16 1)
    printf "\n\n"
    tput bold
    printf "The password is set to \e[31m%s\e[39m\n" "$PASSWORD"
    printf "If you want to set your own password, set the PASSWORD environment variable. e.g. run with:\n"
    printf "docker run -e PASSWORD=\e[92m<YOUR_PASS>\e[39m -p 8787:8787 rocker/rstudio\n"
    tput sgr0
    printf "\n\n"
fi

if [ "${RUNROOTLESS}" = "true" ]; then
    check_user_id="$(grep -F auth-minimum-user-id /etc/rstudio/rserver.conf | sed -e 's/^.*= *//')"
    if [[ "$check_user_id" = "0" ]]; then
        echo "root user already authorized in /etc/rstudio/rserver.conf: $check_user_id, not changed"
    elif [[ -n $check_user_id ]]; then
        echo "minimum authorised user already exists in /etc/rstudio/rserver.conf: $check_user_id"
        echo "RUNROOTLESS=true mode requires setting minimum authorised user to 0. Exiting"
        exit 1
    else
        echo "setting minimum authorised user to 0 (RUNROOTLESS=true)"
        echo auth-minimum-user-id=0 >>/etc/rstudio/rserver.conf
    fi
elif [ "$USERID" -lt 1000 ]; then # Probably a macOS user, https://github.com/rocker-org/rocker/issues/205
    echo "$USERID is less than 1000"
    check_user_id=$(grep -F "auth-minimum-user-id" /etc/rstudio/rserver.conf)
    if [[ -n $check_user_id ]]; then
        echo "minimum authorised user already exists in /etc/rstudio/rserver.conf: $check_user_id"
    else
        echo "setting minimum authorised user to 499"
        echo auth-minimum-user-id=499 >>/etc/rstudio/rserver.conf
    fi
fi

if [ "${RUNROOTLESS}" != "true" ] && [ "$USER" != "$DEFAULT_USER" ]; then
    printf "\n\n"
    tput bold
    printf "Settings by \e[31m\`-e USER=<new username>\`\e[39m is now deprecated and will be removed in the future.\n"
    printf "Please do not use the USER environment variable.\n"
    tput sgr0
    printf "\n\n"
fi

if [ "${RUNROOTLESS}" = "true" ]; then
    echo "deleting the default user ($DEFAULT_USER) since it is not needed."
    userdel "$DEFAULT_USER"
elif [ "$USERID" -ne 1000 ]; then ## Configure user with a different USERID if requested.
    echo "deleting the default user"
    userdel "$DEFAULT_USER"
    echo "creating new $USER with UID $USERID"
    useradd -m "$USER" -u "$USERID"
    mkdir -p "${USERHOME}"
    chown -R "$USER" "${USERHOME}"
    usermod -a -G staff "$USER"
elif [ "$USER" != "$DEFAULT_USER" ]; then
    ## cannot move home folder when it's a shared volume, have to copy and change permissions instead
    cp -r /home/"$DEFAULT_USER" "${USERHOME}"
    ## RENAME the user
    usermod -l "$USER" -d /home/"$USER" "$DEFAULT_USER"
    groupmod -n "$USER" "$DEFAULT_USER"
    usermod -a -G staff "$USER"
    chown -R "$USER":"$USER" "${USERHOME}"
    echo "USER is now $USER"
fi

if [ "${RUNROOTLESS}" != "true" ] && [ "$GROUPID" -ne 1000 ]; then ## Configure the primary GID (whether rstudio or $USER) with a different GROUPID if requested.
    echo "Modifying primary group $(id "${USER}" -g -n)"
    groupmod -o -g "$GROUPID" "$(id "${USER}" -g -n)"
    echo "Primary group ID is now custom_group $GROUPID"
fi

## Add a password to user
echo "$USER:$PASSWORD" | chpasswd

# Use Env flag to know if user should be added to sudoers
if [ "${RUNROOTLESS}" = "true" ]; then
    echo "No sudoers changes needed when running rootless"
elif [[ ${ROOT,,} == "true" ]]; then
    adduser "$USER" sudo && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >>/etc/sudoers
    echo "$USER added to sudoers"
fi

## Change Umask value if desired
if [ "$UMASK" -ne 022 ]; then
    echo "server-set-umask=false" >>/etc/rstudio/rserver.conf
    echo "Sys.umask(mode=$UMASK)" >>"${USERHOME}"/.Rprofile
fi

## Next one for timezone setup
if [ "$TZ" != "Etc/UTC" ]; then
    ln -snf /usr/share/zoneinfo/"$TZ" /etc/localtime && echo "$TZ" >/etc/timezone
fi

## Update Locale if needed
if [ "$LANG" != "en_US.UTF-8" ]; then
    /usr/sbin/locale-gen --lang "$LANG"
    /usr/sbin/update-locale --reset LANG="$LANG"
fi
