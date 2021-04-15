#!/bin/bash
# shellcheck disable=SC2013
LATEST_TAG=$2

for img in $(grep -oP -e "(?<=\\s)[^\\s]+:${LATEST_TAG}" "compose/$1.yml");
  do
      echo "tagging ${img} as ${img/$LATEST_TAG/latest}"
      docker tag "${img}" "${img/$LATEST_TAG/latest}"
      docker push "${img/$LATEST_TAG/latest}"
  done
