#!/bin/bash

# install stan

Rscript -e 'install.packages("cmdstanr", repos = c("https://mc-stan.org/r-packages/", getOption("repos")));
            library(cmdstanr);
            install_cmdstan()'
