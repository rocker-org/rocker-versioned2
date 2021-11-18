# Build combination notes

## Build combination summary

The following combinations of toolkit and tensorflow versions were tested for Nvidia driver versions 460 and 470 and had the same results.

| tensorflow version / toolkit version | 10 | 11 |
| ----------------------------------- | -- | -- |
| 1.15 | succeeds | succeeds |
| 2.2 | succeeds | fails |
| 2.5 | fails | succeeds |
| 2.6 | fails | succeeds |

## Failed build combination notes

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
  * unsupported; tensorflow 2.2 seems to require toolkit 10
* Driver 470, toolkit 10, tensorflow 2.5:
  * fails on missing libraries:
    * libcudart11
    * libcublas11
    * libcublasLt11
    * libcusolver11
    * libcusparse11
  * unsupported; tensorflow 2.5 seems to require toolkit 11
* Driver 470, toolkit 10, tensorflow 2.6:
  * fails on missing libraries:
    * libcudart11
    * libcublas11
    * libcublasLt11
    * libcusolver11
    * libcusparse11
  * unsupported; tensorflow 2.6 seems to require toolkit 11
