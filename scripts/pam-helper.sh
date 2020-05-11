#!/usr/bin/env sh

## Enforces the custom password specified in the PASSWORD environment variable
## The accepted RStudio username is the same as the USER environment variable (i.e., local user name).

set -o nounset

IFS='' read -r password

[ "${USER}" = "${1}" ] && [ "${PASSWORD}" = "${password}" ]
