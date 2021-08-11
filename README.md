[![license](https://img.shields.io/badge/license-GPLv2-blue.svg)](https://opensource.org/licenses/GPL-2.0)
[![Project Status: WIP – Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)

Visit [rocker-project.org](https://rocker-project.org) for more about available Rocker images, configuration, and use.

## Version-stable Rocker images for R >= 4.0.0

For R versions >= 4.0.0, we have implemented a new build system and image architecture under this repository.

For images with R <= 3.6.3, please see the [`rocker-versioned`](https://github.com/rocker-org/rocker-versioned) repository,
or the [`shiny`](https://github.com/rocker-org/shiny), [`geospatial`](https://github.com/rocker-org/geospatial), and [`binder`](https://github.com/rocker-org/binder) repositories for those images, now all consolidated here for R >= 4.0.0.

Instructions for image usage largely follows documentation in the above repositories, except where noted below.

![](https://avatars0.githubusercontent.com/u/9100160?v=3&s=200)

image                                                      | description                                                                                    | pull
-----------------------------------------------------------|------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------
[r-ver](https://hub.docker.com/r/rocker/r-ver)             | Version-stable base R & src build tools                                                        | [![](https://img.shields.io/docker/pulls/rocker/r-ver.svg)](https://hub.docker.com/r/rocker/r-ver)
[rstudio](https://hub.docker.com/r/rocker/rstudio)         | Adds rstudio server                                                                            | [![](https://img.shields.io/docker/pulls/rocker/rstudio.svg)](https://hub.docker.com/r/rocker/rstudio)
[tidyverse](https://hub.docker.com/r/rocker/tidyverse)     | Adds tidyverse & devtools                                                                      | [![](https://img.shields.io/docker/pulls/rocker/tidyverse.svg)](https://hub.docker.com/r/rocker/tidyverse)
[verse](https://hub.docker.com/r/rocker/verse)             | Adds tex & publishing-related packages                                                         | [![](https://img.shields.io/docker/pulls/rocker/verse.svg)](https://hub.docker.com/r/rocker/verse)
[geospatial](https://hub.docker.com/r/rocker/geospatial)   | Adds geospatial packages on top of 'verse'                                                     | [![](https://img.shields.io/docker/pulls/rocker/geospatial.svg)](https://hub.docker.com/r/rocker/geospatial)
[shiny](https://hub.docker.com/r/rocker/shiny)             | Adds shiny server on top of 'r-ver'                                                            | [![](https://img.shields.io/docker/pulls/rocker/shiny.svg)](https://hub.docker.com/r/rocker/shiny)
[shiny-verse](https://hub.docker.com/r/rocker/shiny-verse) | Adds tidyverse packages on top of 'shiny'                                                      | [![](https://img.shields.io/docker/pulls/rocker/shiny-verse.svg)](https://hub.docker.com/r/rocker/shiny-verse)
[binder](https://hub.docker.com/r/rocker/binder)           | Adds requirements to 'geospatial' to run repositories on [mybinder.org](https://mybinder.org/) | [![](https://img.shields.io/docker/pulls/rocker/binder.svg)](https://hub.docker.com/r/rocker/binder)
[cuda](https://hub.docker.com/r/rocker/cuda)               | Adds cuda and Python to 'r-ver' (a.k.a `rocker/r-ver:X.Y.Z-cuda10.1`)                          | [![](https://img.shields.io/docker/pulls/rocker/cuda.svg)](https://hub.docker.com/r/rocker/cuda)
[ml](https://hub.docker.com/r/rocker/ml)                   | Adds rstudio server, tiyverse, devtools to 'cuda'                                              | [![](https://img.shields.io/docker/pulls/rocker/ml.svg)](https://hub.docker.com/r/rocker/ml)
[ml-verse](https://hub.docker.com/r/rocker/ml-verse)       | Adds tex & publishing-related packages & geospatial packages to 'ml'                           | [![](https://img.shields.io/docker/pulls/rocker/ml-verse.svg)](https://hub.docker.com/r/rocker/ml-verse)

**For more information on public container images, please see [the Wiki of this repository](https://github.com/rocker-org/rocker-versioned2/wiki).**

## Notes on new architecture for R >= 4.0.0

- Images are now based on Ubuntu LTS releases rather than Debian and system libraries are tied to the Ubuntu version. Images will use the most recent LTS available at the time when the corresponding R version was released. Thus all 4.0.0 images are based on Ubuntu 20.04.
- We use the [RStudio Package Manager (RSPM)](https://packagemanager.rstudio.com) as our default CRAN mirror.  RSPM serves compiled Linux
   binaries of R packages and greatly speeds up package installs.
- Several images, `r-ver`, and new experimental `ml` and `ml-verse` are now available with CUDA drivers and libraries installed and preconfigured for use on machines with NVIDIA GPUs.  These are available under tags `4.X.X-cudaX.X`, with currently only CUDA 10.1 available pre-built.
- We no longer support `ADD=` runtime triggers for installing Shiny or similar modules.  See below for how to extend images to include custom extensions.
- Shiny images, like RStudio images, now manage processes via the [S6](https://github.com/just-containers/s6-overlay) supervisor system allowing containers to manage multiple background processes gracefully.

### Modifying and extending images in the new architecture

In our new build system, pre-built images are defined with JSON files under [the `stacks/` folder](./stacks)
in this repository.  Each file defines a series of related images.  The `.R` files in [the `build/`
folder](./build) use these to create the actual Dockerfiles under [the `dockerfiles/` folder](./dockerfiles) and images are built by the GitHub Actions workflow.
These Dockerfiles serve as examples of how to build your own custom images.

Importantly, we have moved as much of the detailed install logic out of Dockerfiles and into standalone scripts, or "modules", under the `scripts` directory.  These files are available in all Docker images, under a top-level `/rocker_scripts` directory.  This allows users to extend images by selecting additional modules to install on top of any pre-built images.  For instance, if one wishes to install Shiny Server on top of a base of `rstudio:4.0.0`, one could write a simple Dockerfile as follows:

```Dockerfile
FROM rstudio/rstudio:4.0.0

RUN /rocker_scripts/install_shiny_server.sh
```

Install scripts can generally take a version as a first argument or ingest an environment variable to specify the version to install. So to install fixed versions, one can use either of the following syntaxes:

```Dockerfile
ENV SHINY_SERVER_VERSION 1.5.14.948
RUN /rocker_scripts/install_shiny_server.sh

```

```Dockerfile
RUN /rocker_scripts/install_shiny_server.sh 1.5.14.948
```

In general scripts default to "latest" or the most recent version.
