#!/bin/bash

if ! STAN_TEST_OUTPUT=$(Rscript ./stan.R 2>&1);
then
  echo "failed to run stan test script with error message: $STAN_TEST_OUTPUT"
  exit 1
fi
