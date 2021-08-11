#!/bin/bash

# This script tests for gpu fuctionality

# check for input parameter

if [ $# -ne 1 ]
then
  echo "Error: one input parameter is required"
  echo "Usage: $0 <cuda version>"
  exit 1
fi

if [ $1 -eq 10 ]
then
  CUDA_PACKAGE=cuda-samples-10-0
  CUDA_DIR=cuda-10.0
elif [ $1 -eq 11 ]
then
  CUDA_PACKAGE=cuda-samples-11-1
  CUDA_DIR=cuda-11.1
else
  echo "Error bad value $1 for cuda version"
  echo "cuda version must be either 10 or 11"
  exit 1
fi

# first check for proc file for driver version

echo "checking for driver version file..."
PROC_DRIVER_FILE=/proc/driver/nvidia/version
if [ -f "$PROC_DRIVER_FILE" ]
then
  echo "driver version file found. Contents:"
  cat $PROC_DRIVER_FILE
else
  echo "$PROC_DRIVER_FILE doesn't exist"
  echo "WARNING: Nvidia CUDA driver may not be correctly installed."
fi

# check for driver and gpu info from nvida-smi

printf "\nchecking for driver and gpu info from nvidia-smi...\n"
DRIVER_CHECK_OUTPUT=$(nvidia-smi 2>&1)
if [ $? -ne 0 ]
then
  echo "failed to run nvidia-smi with error message: $DRIVER_CHECK_OUTPUT"
  echo "WARNING: Nvidia CUDA driver may not be correctly installed."
else
  echo "driver and gpu information from from nvidia-smi:"
  # running again because output format removed in variable
  nvidia-smi
fi

# check CUDA Toolkit version with nvcc -V
printf "\nchecking for CUDA Toolkit by running: nvcc -V...\n"
TOOLKIT_CHECK_OUTPUT=$(nvcc -V 2>&1)
if [ $? -ne 0 ]
then
  echo "Failed to run 'nvcc -V' with error message: $TOOLKIT_CHECK_OUTPUT"
  echo "WARNING: CUDA toolkit may not be correctly installed."
else
  echo "toolkit information from 'nvcc -V':"
  echo $TOOLKIT_CHECK_OUTPUT
fi

# run tests from CUDA samples
printf "\nchecking for CUDA Samples...\n"
DPKG_QUERY_SAMPLES=$(dpkg-query -l ${CUDA_PACKAGE} 2>&1)
if [ $? -ne 0 ]
then
  echo "CUDA samples not installed. Please install for additional tests."
else
  echo "CUDA samples installed. Running sample code tests..."

  # run deviceQuery
  printf "\ntesting deviceQuery...\n"
  DEVICE_QUERY_OUTPUT=$(/usr/local/${CUDA_DIR}/samples/1_Utilities/deviceQuery/deviceQuery 2>&1)
  if [ $? -ne 0 ]
  then
    echo "deviceQuery failed with error message: $DEVICE_QUERY_OUTPUT"
  else
    echo "deviceQuery ran with output: $DEVICE_QUERY_OUTPUT"
  fi

  # run bandwidthTest
  printf "\nrunning bandwidthTest...\n"
  BANDWIDTH_TEST_OUTPUT=$(/usr/local/${CUDA_DIR}/samples/1_Utilities/bandwidthTest/bandwidthTest 2>&1)
  if [ $? -ne 0 ]
  then
    echo "bandwidthTest failed error message: $BANDWIDTH_TEST_OUTPUT"
  else
    echo "bandwidthTest ran with output: $BANDWIDTH_TEST_OUTPUT"
  fi

  # run matrixMulCUBLAS
  printf "\nrunning matrixMulCUBLAS...\n"
  SIMPLECUBLAS_OUTPUT=$(/usr/local/${CUDA_DIR}/samples/7_CUDALibraries/simpleCUBLAS/simpleCUBLAS 2>&1)
  if [ $? -ne 0 ]
  then
    echo "simpleCUBLAS failed with error message: $SIMPLECUBLAS_OUTPUT"
  else
    echo "simpleCUBLAS ran with output: $SIMPLECUBLAS_OUTPUT"
  fi
fi

# check for tensorflow
printf "\nchecking for tensorflow install...\n"
TENSORFLOW_TEST_OUTPUT=$(python -c "import tensorflow as tf;print(tf.reduce_sum(tf.random.normal([1000, 1000])))" 2>&1)
if [ $? -ne 0 ]
then
  echo "tensorflow failed with error: $TENSORFLOW_TEST_OUTPUT"
else
  echo "tensorflow installed"
fi

