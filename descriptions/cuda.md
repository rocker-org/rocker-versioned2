# Rocker stack for Machine Learning in R

`rocker/cuda`, `rocker/ml`, and `rocker/ml-verse` are Docker images for machine learning and GPU-based computation in R.

These images are built in modular build system at <https://github.com/rocker-org/rocker-versioned2>.

The dependency stack looks like so:

```txt
-| rocker/cuda
  -| rocker/ml
    -| rocker/ml-verse
```

All three are CUDA compatible and will optionally take R version tags (`rocker/ml:4.0.5`) with the option of additional trailing CUDA version tag (e.g. `rocker/ml:4.0.5-cuda10.1`).

See <https://github.com/rocker-org/rocker-versioned2/wiki> for details of available tags and images.

## Quick start

**Note: GPU use requires [nvidia-docker](https://github.com/NVIDIA/nvidia-docker/)** runtime to run!

Run a bash shell or R command line:

```shell
# CPU-only
docker run --rm -ti rocker/ml R
# Machines with nvidia-docker and GPU support
docker run --gpus all --rm -ti rocker/ml R
```

Or run in RStudio instance:

```shell
docker run --gpus all -e PASSWORD=mu -p 8787:8787 rocker/ml
```

## Tags

See [current `ml` tags](https://hub.docker.com/r/rocker/ml/tags?page=1&ordering=last_updated)
See [current `ml-verse` tags](https://hub.docker.com/r/rocker/ml-verse/tags?page=1&ordering=last_updated)

## Python versions and virtualenvs

The ML images configure a default python virtualenv using the Ubuntu system python (3.8.5 for current Ubuntu 20.04 LTS), see [install_python.sh](https://github.com/rocker-org/rocker-versioned2/blob/master/scripts/install_python.sh).  This virtualenv is user-writable and the default detected by `reticulate` (using `WORKON_HOME` and `PYTHON_VENV_PATH` variables).

Images also configure [pipenv](https://github.com/pypa/pipenv) with [pyenv](https://github.com/pyenv/pyenv) by default.  This makes it very easy to manage projects that require specific versions of Python as well as specific python modules.  For instance, a project using the popular `[greta](https://greta-stats.org/)` package for GPU-accelerated Bayesian inference needs Tensorflow 1.x, which requires Python <= 3.7, might do:

```bash
pipenv --python 3.7
```

In the bash terminal to set up a pipenv-managed virtualenv in the working directory using Python 3.7.  Then in R we can activate this virtualenv

```r
venv <- system("pipenv --venv", inter = TRUE)
reticulate::use_virtualenv(venv, required = TRUE)
```

We can now install tensorflow version needed, e.g.

```r
install.packages("tensorflow")
tensorflow::install_tensorflow(version="1.14.0-gpu", extra_packages="tensorflow-probability==0.7.0")
```

## Notes

All images are based on the current Ubuntu LTS (ubuntu 20.04) and based on the official [NVIDIA CUDA docker build recipes](https://gitlab.com/nvidia/container-images/cuda/)

**PLEASE NOTE**: older images, `rocker/ml-gpu`, `rocker/tensorflow` and `rocker/tensorflow-gpu`, built with cuda 9.0, are deprecated and no longer supported.
