#!/bin/bash
set -e

## CUDA environmental variables configuration for RStudio

## These should be exported as ENV vars too
CUDA_HOME=${CUDA_HOME:-/usr/local/cuda}
PATH={$PATH:-$PATH:$CUDA_HOME/bin}
LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-$LD_LIBRARY_PATH:$CUDA_HOME/lib64:$CUDA_HOME/extras/CUPTI/lib64}
NVBLAS_CONFIG_FILE=${NVBLAS_CONFIG_FILE:-/etc/nvblas.conf}

## cli R inherits these, but RStudio needs to have these set in as follows:
## (From https://tensorflow.rstudio.com/tools/local_gpu.html#environment-variables)
echo "CUDA_HOME=$CUDA_HOME" >> ${R_HOME}/etc/Renviron.site
echo "PATH=$PATH" >> ${R_HOME}/etc/Renviron.site

if test -f /etc/rstudio/rserver.conf; then
  sed -i '/^rsession-ld-library-path/d' /etc/rstudio/rserver.conf
  echo "rsession-ld-library-path=$LD_LIBRARY_PATH" >> /etc/rstudio/rserver.conf
fi

## nvblas configuration
touch /var/log/nvblas.log && chown :staff /var/log/nvblas.log
chmod a+rw /var/log/nvblas.log

## Configure R & RStudio to use drop-in CUDA blas
## Allow R to use CUDA for BLAS, with fallback on openblas
## NOTE: NVBLAS_CPU_BLAS_LIB must be correct for UBUNTU_VERSION selected in scripts/install_R.sh#L25
echo 'NVBLAS_LOGFILE /var/log/nvblas.log
NVBLAS_CPU_BLAS_LIB /usr/lib/x86_64-linux-gnu/openblas-pthread/libblas.so.3
NVBLAS_GPU_LIST ALL' > /etc/nvblas.conf

echo "NVBLAS_CONFIG_FILE=$NVBLAS_CONFIG_FILE" >> ${R_HOME}/etc/Renviron.site

## Test GPU fuctionality
TEST_FAIL=false
# driver
PROC_DRIVER_FILE=/proc/driver/nvidia/version
if [ ! -f "$PROC_DRIVER_FILE" ]
then
  echo "$PROC_DRIVER_FILE doesn't exist" | tee -a /var/log/nvblas.log
  echo "WARNING: CUDA driver may not be correctly installed." | tee -a /var/log/nvblas.log
  TEST_FAIL=true
fi
# toolkit
if ! TOOLKIT_CHECK_OUTPUT=$(nvcc -V 2>&1);
then
  echo "Failed to run 'nvcc -V' with error message: $TOOLKIT_CHECK_OUTPUT" | tee -a /var/log/nvblas.log
  echo "WARNING: CUDA toolkit may not be correctly installed." | tee -a /var/log/nvblas.log
  TEST_FAIL=true
fi
# nvblas
if ! NVBLAS_OUTPUT=$(Rscript ../tests/gpu/misc/nvblas.R 2>&1);
then
  echo "Failed nvBLAS test with error $NVBLAS_OUTPUT" | tee -a /var/log/nvblas.log
  TEST_FAIL=true
fi
# tensorflow
if ! TF_OUTPUT=$(Rscript ../tests/gpu/misc/examples_tf.R 2>&1);
then
  echo "Failed tensorflow test with error $TF_OUTPUT" | tee -a /var/log/nvblas.log
  TEST_FAIL=true
else
  GPU_STR="device:GPU:0"
  if [[ "$TF_OUTPUT" == *"$GPU_STR"* ]]
  then
    echo "tensorflow GPU test succeeded" | tee -a /var/log/nvblas.log
    echo "output in the log" | tee -a /var/log/nvblas.log
    echo "$TF_OUTPUT" >> /var/log/nvblas.log
  else
    echo "CPU tensorflow test succeeded" | tee -a /var/log/nvblas.log
    echo "Failed GPU tensorflow test. See log for details." | tee -a /var/log/nvblas.log
    echo "$TF_OUTPUT" >> /var/log/nvblas.log
    TEST_FAIL=true
  fi
fi

if [ "$TEST_FAIL" = true ]
then
  echo "WARNING: at least one of the GPU functionality tests has failed." | tee -a /var/log/nvblas.log
  echo "Please run rocker-versioned2/tests/gpu/test-gpu.sh script for more detailed information." | tee -a /var/log/nvblas.log
fi
## end GPU tests

## We don't want to set LD_PRELOAD globally
##ENV LD_PRELOAD=/usr/local/cuda/lib64/libnvblas.so
#
### Instead, we will set it before calling R, Rscript, or RStudio:
#mv /usr/bin/R /usr/bin/R_
#mv /usr/bin/Rscript /usr/bin/Rscript_
#
#echo '\#!/bin/sh \
#      \n LD_PRELOAD=/usr/local/cuda/lib64/libnvblas.so /usr/bin/R_ "$@"' \
#      > /usr/bin/R && \
#    chmod +x /usr/bin/R && \
#    echo '#!/bin/sh \
#          \n LD_PRELOAD=/usr/local/cuda/lib64/libnvblas.so /usr/bin/Rscript_ "$@"' \
#      > /usr/bin/Rscript && \
#    chmod +x /usr/bin/Rscript
#
#echo '#!/usr/bin/with-contenv bash \
#      \n## load /etc/environment vars first: \
#      \n for line in \$( cat /etc/environment ) ; do export $line ; done \
#      \n export LD_PRELOAD=/usr/local/cuda/lib64/libnvblas.so \
#      \n exec /usr/lib/rstudio-server/bin/rserver --server-daemonize 0' \
#      > /etc/services.d/rstudio/run
