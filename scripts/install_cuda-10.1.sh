#!/bin/bash

apt-get update && apt-get install -y --no-install-recommends \
gnupg2 curl ca-certificates && \
    curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub | apt-key add - && \
    echo "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64 /" > /etc/apt/sources.list.d/cuda.list && \
    echo "deb https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64 /" > /etc/apt/sources.list.d/nvidia-ml.list && \
    apt-get purge --autoremove -y curl && \
rm -rf /var/lib/apt/lists/*

CUDA_VERSION=${CUDA_VERSION:-10.1.243}
CUDA_PKG_VERSION=${CUDA_PKG_VERSION:-10-1=$CUDA_VERSION-1}

# For libraries in the cuda-compat-* package: https://docs.nvidia.com/cuda/eula/index.html#attachment-a
apt-get update && apt-get install -y --no-install-recommends \
    cuda-cudart-$CUDA_PKG_VERSION \
    cuda-compat-10-1 && \
    ln -s cuda-10.1 /usr/local/cuda && \
    rm -rf /var/lib/apt/lists/*

# Required for nvidia-docker v1
echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf && \
    echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf


## PATH & LD_LIBRARY_PATH are wrong?
PATH=${PATH:-/usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}}
LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-/usr/local/nvidia/lib:/usr/local/nvidia/lib64}

# nvidia-container-runtime
NVIDIA_VISIBLE_DEVICES=${NVIDIA_VISIBLE_DEVICES:-all}
NVIDIA_DRIVER_CAPABILITIES=${NVIDIA_DRIVER_CAPABILITIES:-"compute,utility"}
NVIDIA_REQUIRE_CUDA=${NVIDIA_REQUIRE_CUDA:-"cuda>=10.1 brand=tesla,driver>=384,driver<385 brand=tesla,driver>=396,driver<397 brand=tesla,driver>=410,driver<411"}

## Tensorflow config for cuda runtime.
## Adapted from:

ARCH=
CUDA=10.1
CUDNN=7.6.4.38-1
CUDNN_MAJOR_VERSION=7
LIB_DIR_PREFIX=x86_64
LIBNVINFER=6.0.1-1
LIBNVINFER_MAJOR_VERSION=6

#SHELL ["/bin/bash", "-c"]
# Pick up some TF dependencies
        # There appears to be a regression in libcublas10=10.2.2.89-1 which
        # prevents cublas from initializing in TF. See
        # https://github.com/tensorflow/tensorflow/issues/9489#issuecomment-562394257
apt-get update && apt-get install -y --no-install-recommends --allow-downgrades \
        build-essential \
        cuda-command-line-tools-10-1 \
        libcublas10=10.2.1.243-1 \
        cuda-nvrtc-10-1 \
        cuda-cufft-10-1 \
        cuda-curand-10-1 \
        cuda-cusolver-10-1 \
        cuda-cusparse-10-1 \
        curl \
        libcudnn7=${CUDNN}+cuda10.1 \
        libfreetype6-dev \
        libhdf5-serial-dev \
        libzmq3-dev \
        pkg-config \
        software-properties-common \
        unzip

# Install TensorRT if not building for PowerPC
apt-get update && \
        apt-get install -y --no-install-recommends libnvinfer${LIBNVINFER_MAJOR_VERSION}=${LIBNVINFER}+cuda${CUDA} \
        libnvinfer-plugin${LIBNVINFER_MAJOR_VERSION}=${LIBNVINFER}+cuda${CUDA} \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/*

# For CUDA profiling, TensorFlow requires CUPTI.
LD_LIBRARY_PATH==${LD_LIBRARY_PATH:-/usr/local/cuda/extras/CUPTI/lib64:/usr/local/cuda/lib64:$LD_LIBRARY_PATH}

# Link the libcuda stub to the location where tensorflow is searching for it and reconfigure
# dynamic linker run-time bindings
ln -s /usr/local/cuda/lib64/stubs/libcuda.so /usr/local/cuda/lib64/stubs/libcuda.so.1
echo "/usr/local/cuda/lib64/stubs" > /etc/ld.so.conf.d/z-cuda-stubs.conf
ldconfig

## Add nvtop
#/rocker_scripts/install_nvtop.sh

