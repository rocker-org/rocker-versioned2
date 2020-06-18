#/bin/bash

LATEST_TAG=$2


for img in $(cat compose/$1.yml | grep -oP -e "(?<=\\s)[^\\s]+:${LATEST_TAG}"); 
  do
      echo "tagging ${img} as ${img/$LATEST_TAG/latest}"
      docker tag ${img} ${img/$LATEST_TAG/latest}
      docker push ${img/$LATEST_TAG/latest}
  done

