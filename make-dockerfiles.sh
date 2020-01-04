#!/bin/sh
set -e

# get the latest versions grid,. this prevents Make from updating
curl -sL https://bit.ly/2QKF14P | tr -d '\r' | sed -E " s/,$/,NULL/g ; s/,,/,NULL,/g" > /tmp/versions-grid.csv
if ! cmp versions-grid.csv /tmp/versions-grid.csv >/dev/null 2>&1; then
  cp /tmp/versions-grid.csv versions-grid.csv
fi

rm -f /tmp/env-names
ROCKER_VARS=$(head -1 versions-grid.csv | sed "s/,/ /g")
for var in $ROCKER_VARS; do
  echo "$var="  >> /tmp/env-names
done

for line in $(tail +2 versions-grid.csv); do
  
  # Remove values from last run
  rm -f /tmp/env-vals /tmp/env-block /tmp/scripts-block
  for var in "$ROCKER_VARS EXPOSE_BLOCK CMD_BLOCK ENTRYPOINT_BLOCK"; do unset $var; done

  # Create block of environment variables 
  for var in $(echo $line | sed "s/,/ /g"); do
    echo $var >> /tmp/env-vals
  done
  paste -d '\0' /tmp/env-names /tmp/env-vals | grep -v "NULL" > /tmp/env-block
  source /tmp/env-block
  sed -i.bak 's/^/ENV /' /tmp/env-block
  
  # Create block of scripts to run (maybe a more generic way to template these?)
  if [ ! -z "${R_VERSION}" ]; then echo "RUN /tmp/scripts/install_R.sh" >> /tmp/scripts-block; fi
  if [ ! -z "${RSTUDIO_VERSION}" ]; then echo "RUN /tmp/scripts/install_rstudio.sh" >> /tmp/scripts-block; fi

  # Write Docker image files from templates
  if [ ! -z "${DOCKER_EXPOSE}" ]; then EXPOSE_BLOCK="EXPOSE $(echo ${DOCKER_EXPOSE} | sed 's/;/ /g')"; fi
  if [ ! -z "${DOCKER_CMD}" ]; then CMD_BLOCK="CMD $(echo \"${DOCKER_CMD}\" | sed 's/\//\\\//g')"; fi
  if [ ! -z "${DOCKER_ENTRYPOINT}" ]; then ENTRY_BLOCK="CMD $(echo \"${DOCKER_ENTRYPOINT}\" | sed 's/\//\\\//g')"; fi

  cat Dockerfile.template | \
  sed "s/%%BASE_IMAGE%%/${BASE_IMAGE}/g" | \
  sed "/%%VERSIONS_BLOCK%%/ { r /tmp/env-block
        d;}" | \
  sed "/%%SCRIPTS_BLOCK%%/ { r /tmp/scripts-block
      d;}" | \
  sed "s/%%EXPOSE_BLOCK%%/${EXPOSE_BLOCK}/g"| \
  sed "s/%%CMD_BLOCK%%/${CMD_BLOCK}/g" | \
  sed "s/%%ENTRYPOINT_BLOCK%%/${ENTRYPOINT_BLOCK}/g" \
  > Dockerfiles/Dockerfile_${ROCKER_IMAGE}_${ROCKER_TAG}
  
done
  
