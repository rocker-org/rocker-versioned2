#!/bin/bash
set -e

# Tensorflow 1.x is required for numerous projects.  
# Even the most recent of the 1.x, 1.15.5 is compatible only 
# with CUDA 10.0 versions of the following libraries.

# Fortunately, these are available from the NVIDIA Ubuntu debian PPA repos added in 10.1 images

apt-get update && apt-get install -y \
  cuda-cudart-10-0 \
  cuda-cufft-10-0 \
  cuda-cusolver-10-0 \
  cuda-curand-10-0 \
  cuda-cusparse-10-0 \
  cuda-cublas-10-0

