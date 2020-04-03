#!/bin/bash

R_DOC_DIR=/usr/share/R/doc
R_INCLUDE_DIR=/usr/share/R/include
R_SHARE_DIR=/usr/share/R/share
RSTUDIO_DEFAULT_R_VERSION_HOME=$R_HOME
RSTUDIO_DEFAULT_R_VERSION=3.6.3
PATH=$PATH:/usr/lib/rstudio-server/bin
rsession --standalone=1 \
         --program-mode=server \
         --log-stderr=1 \
         --session-timeout-minutes=0 \
         --user-identity=rstudio \
         --www-port=8787




