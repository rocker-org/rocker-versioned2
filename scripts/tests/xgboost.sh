#!/bin/bash

if ! XGBOOST_TEST_OUTPUT=$(Rscript ./xgboost.R 2>&1);
then
  echo "failed to run xgboost test script with error message: $XGBOOST_TEST_OUTPUT"
  exit 1
fi
