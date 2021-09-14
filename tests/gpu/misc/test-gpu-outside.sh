#!/bin/bash

# This script tests for gpu fuctionality in any found images named rocker_cuda10 or rocker_cuda11

docker ps | tail -n +2 | awk -f /root/cuda_ver.awk

cat /test-gpu-10.log /test-gpu-11.log >> /test-gpu.log
