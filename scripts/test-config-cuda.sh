#!/bin/bash
set -e

# require one command line argument
if [ "$#" -ne 1 ]
then
  echo "Error: one argument for log location required (e.g. ./gpu-test.log)"
  echo "Usage: $0 log-location"
  exit 1
fi

# set log location from command invokation
LOG_LOC=$1
TEST_FAIL=false

# driver
PROC_DRIVER_FILE=/proc/driver/nvidia/version
if [ ! -f "$PROC_DRIVER_FILE" ]
then
  echo "$PROC_DRIVER_FILE doesn't exist" | tee -a $LOG_LOC
  echo "WARNING: CUDA driver may not be correctly installed." | tee -a $LOG_LOC
  TEST_FAIL=true
else
  while read line; do
    IFS=' ' read -ra tmp_array <<< $line
    if [ ${tmp_array[0]} = "NVRM" ] && [ ${tmp_array[1]} = "version:" ]
    then
      VERSION_DRIVER=${tmp_array[7]}
    fi
  done < $PROC_DRIVER_FILE
fi

echo $VERSION_DRIVER | tee -a $LOG_LOC

# toolkit
if ! TOOLKIT_CHECK_OUTPUT=$(nvcc -V 2>&1);
then
  echo "Failed to run 'nvcc -V' with error message: $TOOLKIT_CHECK_OUTPUT" | tee -a $LOG_LOC
  echo "WARNING: CUDA toolkit may not be correctly installed." | tee -a $LOG_LOC
  TEST_FAIL=true
else
  # parse output to get version number
  while IFS= read -r line
  do
    IFS=' ' read -ra tmp_array <<< $line
    if [ "${tmp_array[3]}" = "release" ]
    then
      VERSION_TOOLKIT=${tmp_array[5]}
    fi
  done <<< $TOOLKIT_CHECK_OUTPUT
fi

echo $VERSION_TOOLKIT | tee -a $LOG_LOC

# tensorflow
if ! VERSION_TF_OUTPUT=$(python -c 'import tensorflow as tf; print(tf.__version__)' 2>&1);
then
  echo "Error: trying to get tensorflow version: $TF_VERSION"
else
  while IFS= read -r line
  do
    VERSION_TF=$line
  done <<< $VERSION_TF_OUTPUT
fi

echo $VERSION_TF | tee -a $LOG_LOC

if [ "$TEST_FAIL" = true ]
then
  echo "WARNING: at least one of the GPU functionality tests has failed." | tee -a $LOG_LOC
  echo "Please run rocker-versioned2/tests/gpu/test-gpu.sh script for more detailed information." | tee -a $LOG_LOC
fi
