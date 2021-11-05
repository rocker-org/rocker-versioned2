#!/bin/bash
set -e

# set log location from command invokation
LOG_LOC=$1
TEST_FAIL=false

#!/bin/bash
set -e

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
  # 2 possible command line options
  # 1) we could parse /proc/driver/nvidia/version, but output isn't easy to parse:
  #      NVRM version: NVIDIA UNIX x86_64 Kernel Module  470.74  Mon Sep 13 23:09:15 UTC 2021
  #      GCC version:  gcc version 9.3.0 (Ubuntu 9.3.0-17ubuntu1~20.04)
  # 2) nvidia-smi --query-gpu=driver_version --format=csv
  #    output is easy to parse:
  #      driver_version
  #      470.74
  #    but nvidia-smi may require communication with the card that we won't have.
  #    testing will be needed
  while read line; do
    IFS=' ' read -ra tmp_array <<< $line
    if [ ${tmp_array[0]} = "NVRM" ] && [ ${tmp_array[1]} = "version:" ]
    then
      VERSION_DRIVER=${tmp_array[7]}
    fi
  done < $PROC_DRIVER_FILE
fi

echo $VERSION_DRIVER

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

echo $VERSION_TOOLKIT

# tensorflow
if ! VERSION_TF_OUTPUT=`python -c 'import tensorflow as tf; print(tf.__version__)' 2>&1`;
then
  echo "Error: trying to get tensorflow version: $TF_VERSION"
else
  while IFS= read -r line
  do
    VERSION_TF=$line
  done <<< $VERSION_TF_OUTPUT
fi

echo $VERSION_TF

if [ "$TEST_FAIL" = true ]
then
  echo "WARNING: at least one of the GPU functionality tests has failed." | tee -a $LOG_LOC
  echo "Please run rocker-versioned2/tests/gpu/test-gpu.sh script for more detailed information." | tee -a $LOG_LOC
fi
