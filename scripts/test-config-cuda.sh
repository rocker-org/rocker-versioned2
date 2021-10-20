$LOG_LOC#!/bin/bash
set -e

# set log location from command invokation
LOG_LOC=$2
TEST_FAIL=false

# driver
PROC_DRIVER_FILE=/proc/driver/nvidia/version
if [ ! -f "$PROC_DRIVER_FILE" ]
then
  echo "$PROC_DRIVER_FILE doesn't exist" | tee -a $LOG_LOC
  echo "WARNING: CUDA driver may not be correctly installed." | tee -a $LOG_LOC
  TEST_FAIL=true
fi
# toolkit
if ! TOOLKIT_CHECK_OUTPUT=$(nvcc -V 2>&1);
then
  echo "Failed to run 'nvcc -V' with error message: $TOOLKIT_CHECK_OUTPUT" | tee -a $LOG_LOC
  echo "WARNING: CUDA toolkit may not be correctly installed." | tee -a $LOG_LOC
  TEST_FAIL=true
fi
# nvblas
if ! NVBLAS_OUTPUT=$(Rscript ../tests/gpu/misc/nvblas.R 2>&1);
then
  echo "Failed nvBLAS test with error $NVBLAS_OUTPUT" | tee -a $LOG_LOC
  TEST_FAIL=true
fi
# tensorflow
if ! TF_OUTPUT=$(Rscript ../tests/gpu/misc/examples_tf.R 2>&1);
then
  echo "Failed tensorflow test with error $TF_OUTPUT" | tee -a $LOG_LOC
  TEST_FAIL=true
else
  GPU_STR="device:GPU:0"
  if [[ "$TF_OUTPUT" == *"$GPU_STR"* ]]
  then
    echo "tensorflow GPU test succeeded" | tee -a $LOG_LOC
    echo "output in the log" | tee -a $LOG_LOC
    echo "$TF_OUTPUT" >> $LOG_LOC
  else
    echo "CPU tensorflow test succeeded" | tee -a $LOG_LOC
    echo "Failed GPU tensorflow test. See log for details." | tee -a $LOG_LOC
    echo "$TF_OUTPUT" >> $LOG_LOC
    TEST_FAIL=true
  fi
fi

if [ "$TEST_FAIL" = true ]
then
  echo "WARNING: at least one of the GPU functionality tests has failed." | tee -a $LOG_LOC
  echo "Please run rocker-versioned2/tests/gpu/test-gpu.sh script for more detailed information." | tee -a $LOG_LOC
fi
