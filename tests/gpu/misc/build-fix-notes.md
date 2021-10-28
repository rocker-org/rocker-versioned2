I'll just use this text file to store notes about build issues so I can create a PR and we can start discussing

## Failed build combinations:

* Driver 470, toolkit 11, tensorflow 2.2:
  * Tensorflow 2.2 seems to require toolkit 10.
  * I was able to load the required libraries in version 10 with apt. They are:
    * libcudart10
    * libcusolver10
    * libcublas10
    * libcusparse10
  * Unfortunately, it also requires cudnn7 which isn't available from apt.
    * maybe a repo can be added that has cudnn7
    * other option is to build from download from NVIDIA, but I don't know how this would work within the build
  * mark as unsupported

## Working build combinations
