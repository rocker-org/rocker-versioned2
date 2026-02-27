#!/bin/bash

# Xgboost

set -e
set -x

apt update && apt install -y software-properties-common

# install nvidia toolkit
apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/7fa2af80.pub
add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/ /"
apt install -y --allow-change-held-packages libnccl2 \
                                            libnccl-dev \
                                            cuda-nvcc-11-3 \
                                            libnvidia-compute-470 \
                                            ocl-icd-opencl-dev \
                                            clinfo
ln -s /usr/lib/x86_64-linux-gnu/libOpenCL.so.1 /usr/lib/libOpenCL.so

# install cmake
apt update && apt install -y build-essential libssl-dev gcc-8 g++-8
update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 80 --slave /usr/bin/g++ g++ /usr/bin/g++-8 --slave /usr/bin/gcov gcov /usr/bin/gcov-8
mkdir /tmp/cmake
cd /tmp/cmake
wget https://github.com/Kitware/CMake/releases/download/v3.20.0/cmake-3.20.0.tar.gz
tar -zxvf cmake-3.20.0.tar.gz
cd /tmp/cmake/cmake-3.20.0
./bootstrap
make
make install

# compile xgboost
cd /root
git clone --recursive https://github.com/dmlc/xgboost
mkdir /root/xgboost/build
cd /root/xgboost/build
cmake .. -DUSE_CUDA=ON -DR_LIB=ON -DUSE_NCCL=ON -DNCCL_ROOT=/usr/lib/x86_64-linux-gnu
make install -j4
