
#!/bin/bash

## build ARGs
NCPUS=${NCPUS:-1}

set -e
apt-get update -qq && apt-get -y --no-install-recommends install \
    libxml2-dev \
    libcairo2-dev \
    libgit2-dev \
    default-libmysqlclient-dev \
    libpq-dev \
    libsasl2-dev \
    libsqlite3-dev \
    libssh2-1-dev \
    unixodbc-dev && \
  rm -rf /var/lib/apt/lists/*


install2.r --error --skipinstalled -r $CRAN -n $NCPUS \
    tidyverse \
    devtools \
    rmarkdown \
    BiocManager \
    vroom \
    gert

## dplyr database backends 
install2.r --error --skipinstalled -r $CRAN -n $NCPUS \
    arrow \
    dbplyr \
    DBI \
    dtplyr \
    nycflights13 \
    Lahman \
    RMariaDB \
    RPostgres \
    RSQLite \
    fst

## a bridge to far? -- brings in another 60 packages
# install2.r --error --skipinstalled -r $CRAN -n $NCPUS tidymodels 

 rm -rf /tmp/downloaded_packages


