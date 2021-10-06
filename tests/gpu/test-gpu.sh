#!/bin/bash

# This script tests for gpu fuctionality

# check for input parameter

if [ $# -ne 2 ]
then
  echo "Error: one input parameter is required"
  echo "Usage: $0 <cuda version> <log file>"
  exit 1
fi

if [ "$1" -eq 10 ]
then
  CUDA_PACKAGE=cuda-samples-10-0
  CUDA_DIR=cuda-10.0
elif [ "$1" -eq 11 ]
then
  CUDA_PACKAGE=cuda-samples-11-1
  CUDA_DIR=cuda-11.1
else
  echo "Error bad value $1 for cuda version"
  echo "cuda version must be either 10 or 11"
  exit 1
fi

LOG_LOC=$2

# first check for proc file for driver version

echo "checking for driver version file..." | tee -a "$LOG_LOC"
PROC_DRIVER_FILE=/proc/driver/nvidia/version
if [ -f "$PROC_DRIVER_FILE" ]
then
  echo "driver version file found. Contents sent to log." | tee -a "$LOG_LOC"
  cat $PROC_DRIVER_FILE >> "$LOG_LOC"
else
  echo "$PROC_DRIVER_FILE doesn't exist" | tee -a "$LOG_LOC"
  echo "WARNING: Nvidia CUDA driver may not be correctly installed." | tee -a "$LOG_LOC"
fi

# check for driver and gpu info from nvida-smi

printf "\nchecking for driver and gpu info from nvidia-smi...\n" | tee -a "$LOG_LOC"
if ! DRIVER_CHECK_OUTPUT=$(nvidia-smi 2>&1);
then
  echo "failed to run nvidia-smi with error message: $DRIVER_CHECK_OUTPUT" | tee -a "$LOG_LOC"
  echo "WARNING: Nvidia CUDA driver may not be correctly installed." | tee -a "$LOG_LOC"
else
  echo "driver and gpu information from from nvidia-smi sent to log" | tee -a "$LOG_LOC"
  # running again because output format removed in variable
  nvidia-smi >> "$LOG_LOC"
fi

# check CUDA Toolkit version with nvcc -V
printf "\nchecking for CUDA Toolkit by running: nvcc -V...\n" | tee -a "$LOG_LOC"
if ! TOOLKIT_CHECK_OUTPUT=$(nvcc -V 2>&1);
then
  echo "Failed to run 'nvcc -V' with error message: $TOOLKIT_CHECK_OUTPUT" | tee -a "$LOG_LOC"
  echo "WARNING: CUDA toolkit may not be correctly installed." | tee -a "$LOG_LOC"
else
  echo "toolkit information from 'nvcc -V' sent to log." | tee -a "$LOG_LOC"
  echo "$TOOLKIT_CHECK_OUTPUT" >> "$LOG_LOC"
fi

# run tests from CUDA samples
printf "\nchecking for CUDA Samples...\n" | tee -a "$LOG_LOC"
dpkg_cmd="dpkg-query -l ${CUDA_PACKAGE} 2>&1"
tee_cmd="tee -a $LOG_LOC"
if ! $dpkg_cmd | $tee_cmd
then
  echo "CUDA samples not installed. Please install for additional tests." | tee -a "$LOG_LOC"
else
  echo "CUDA samples installed. Running sample code tests..." | tee -a "$LOG_LOC"

  # run deviceQuery
  printf "\ntesting deviceQuery...\n" | tee -a "$LOG_LOC"
  if ! DEVICE_QUERY_OUTPUT=$(/usr/local/${CUDA_DIR}/samples/1_Utilities/deviceQuery/deviceQuery 2>&1);
  then
    echo "deviceQuery failed with error message: $DEVICE_QUERY_OUTPUT" | tee -a "$LOG_LOC"
  else
    echo "deviceQuery succeeded with output sent to log" | tee -a "$LOG_LOC"
    # rerunning deviceQuery becuase formatting lost in variable
    /usr/local/${CUDA_DIR}/samples/1_Utilities/deviceQuery/deviceQuery >> "$LOG_LOC" 2>&1
  fi

  # run bandwidthTest
  printf "\nrunning bandwidthTest...\n" | tee -a "$LOG_LOC"
  if ! BANDWIDTH_TEST_OUTPUT=$(/usr/local/${CUDA_DIR}/samples/1_Utilities/bandwidthTest/bandwidthTest 2>&1);
  then
    echo "bandwidthTest failed error message: $BANDWIDTH_TEST_OUTPUT" | tee -a "$LOG_LOC"
  else
    echo "bandwidthTest succeeded with output sent to log." | tee -a "$LOG_LOC"
    echo "$BANDWIDTH_TEST_OUTPUT" >> "$LOG_LOC"
  fi

  # run matrixMulCUBLAS
  printf "\nrunning simpleCUBLAS...\n" | tee -a "$LOG_LOC"
  if ! SIMPLECUBLAS_OUTPUT=$(/usr/local/${CUDA_DIR}/samples/7_CUDALibraries/simpleCUBLAS/simpleCUBLAS 2>&1);
  then
    echo "simpleCUBLAS failed with error message: $SIMPLECUBLAS_OUTPUT" | tee -a "$LOG_LOC"
  else
    echo "simpleCUBLAS succeeded with output sent to log." | tee -a "$LOG_LOC"
    echo "$SIMPLECUBLAS_OUTPUT" >> "$LOG_LOC"
  fi
fi

# test nvBLAS
echo "running test of nvBLAS in R..." | tee -a "$LOG_LOC"
if ! NVBLAS_OUTPUT=$(Rscript /nvblas.R 2>&1);
then
  echo "Failed nvBLAS test with error $NVBLAS_OUTPUT" | tee -a "$LOG_LOC"
else
  echo "nvBLAS test succeeded" | tee -a "$LOG_LOC"
  echo "output in the log" | tee -a "$LOG_LOC"
  echo "$NVBLAS_OUTPUT" >> "$LOG_LOC"
fi

# check for tensorflow
printf "\ntest tensorflow versions in R\n" | tee -a "$LOG_LOC"

declare -a test_versions=( "1.15.5" "2.2" "2.5" "2.6" )
for ver in "${test_versions[@]}"
do
  if [ "$ver" != "1.15.5" ]
  then
    ver1_package_name="nvidia-tensorflow[horovod]"
    echo "uninstalling $ver1_package_name if installed..." | tee -a "$LOG_LOC"
    pip uninstall --yes "$ver1_package_name" >> "$LOG_LOC" 2>&1
    echo "installing tensorflow ${ver}..." | tee -a "$LOG_LOC"
    R -e 'install.packages("tensorflow")' >> "$LOG_LOC" 2>&1
    if ! eval "$(R -e "tensorflow::install_tensorflow(version=\"${ver}-gpu\", extra_packages=\"tensorflow-probability==0.7.0\")" >> "$LOG_LOC" 2>&1)"
    then
      echo "Failed to install tensorflow version ${ver}" | tee -a "$LOG_LOC"
      exit 1
    fi
  fi
  echo "running test of tensorflow in R..." | tee -a "$LOG_LOC"
  if ! TF_OUTPUT=$(Rscript /examples_tf.R 2>&1);
  then
    echo "Failed tensorflow test for version ${ver} with error $TF_OUTPUT" | tee -a "$LOG_LOC"
  else
    GPU_STR="device:GPU:0"
    if [[ "$TF_OUTPUT" == *"$GPU_STR"* ]]
    then
      echo "GPU tensorflow test succeeded for version ${ver}" | tee -a "$LOG_LOC"
      echo "output in the log" | tee -a "$LOG_LOC"
      echo "$TF_OUTPUT" >> "$LOG_LOC"
    else
      echo "CPU tensorflow test succeeded for version ${ver}" | tee -a "$LOG_LOC"
      echo "GPU tensorflow test failed for version ${ver}. See log for details." | tee -a "$LOG_LOC"
      echo "$TF_OUTPUT" >> "$LOG_LOC"
    fi
  fi
  echo " "
done
