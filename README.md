# Version-stable Rocker images <img src="https://avatars0.githubusercontent.com/u/9100160?v=3&s=200" align="right">

<!-- badges: start -->

[![license](https://img.shields.io/badge/license-GPLv2-blue.svg)](https://opensource.org/licenses/GPL-2.0)
[![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![Update container definition files](https://github.com/rocker-org/rocker-versioned2/actions/workflows/dockerfiles.yml/badge.svg)](https://github.com/rocker-org/rocker-versioned2/actions/workflows/dockerfiles.yml)
[![Build & Push Core images](https://github.com/rocker-org/rocker-versioned2/actions/workflows/core.yml/badge.svg)](https://github.com/rocker-org/rocker-versioned2/actions/workflows/core.yml)
[![Build & Push R devel images and RStudio daily build images](https://github.com/rocker-org/rocker-versioned2/actions/workflows/devel.yml/badge.svg)](https://github.com/rocker-org/rocker-versioned2/actions/workflows/devel.yml)

<!-- badges: end -->

Visit [rocker-project.org](https://rocker-project.org) for more about available Rocker images, configuration, and use.

## Overview

This repository provides [`rocker/r-ver`](https://hub.docker.com/r/rocker/r-ver) and its derived images,
alternate stack to [`r-base`](https://hub.docker.com/_/r-base),
with an emphasis on reproducibility.

Compared to `r-base`, this stack:

- Builds on Ubuntu LTS rather than Debian and system libraries are tied to the Ubuntu version.
  Images will use the most recent LTS available at the time when the corresponding R version was released.
  - Since compatibility problems are likely to occur immediately after the release of a new Ubuntu LTS,
    the version to be used is the one that is at least 90 days past release.
    - `rocker/r-ver:4.0.0` is based on Ubuntu 20.04 (`ubuntu:focal`)
      because no interval was set at the time of the Ubuntu 20.04 release.
- Installs a fixed version of R itself from source, rather than whatever is already packaged for Ubuntu
  (the `r-base` stack gets the latest R version as a binary from Debian unstable).
- The only platforms available are `linux/amd64` and `linux/arm64`
  (arm64 images are experimental and only available for `rocker/r-ver` 4.1.0 or later).
- Set [the Posit Public Package Manager (RStudio Package Manager, RSPM)](https://packagemanager.posit.co)
  as default CRAN mirror.
  For the amd64 platform, RSPM serves compiled Linux binaries of R packages and greatly speeds up package installs.
- Non-latest R version images installs all R packages from a fixed snapshot of CRAN mirror at a given date.
  This setting ensures that the same version of the R package is installed no matter when the installation is performed.
  - In addition to CRAN mirror, the version of RStudio Server installed in `rocker/rstudio` and
    the date of CTAN mirror set in `rocker/verse` are also fixed.
    Please check [the document about versions](https://github.com/rocker-org/rocker-versioned2/wiki/Versions) for details.
- Provides images that are generally smaller than the `r-base` series.

_Note: This repository is for R >= 4.0.0 images.
For images with R <= 3.6.3, please see the [`rocker-versioned`](https://github.com/rocker-org/rocker-versioned) repository,
or the [`shiny`](https://github.com/rocker-org/shiny), [`geospatial`](https://github.com/rocker-org/geospatial),
and [`binder`](https://github.com/rocker-org/binder) repositories._

## Pre-built images

The following images have been built and are available on DockerHub or [GitHub Container Registry](https://github.com/orgs/rocker-org/packages?repo_name=rocker-versioned2).

For more information about these container images, please see [the Wiki of this repository](https://github.com/rocker-org/rocker-versioned2/wiki).

### Image list

Check [the Rocker project site](https://rocker-project.org/images/#the-versioned-stack) for the list of images.

### Tags

Check [the Wiki](https://github.com/rocker-org/rocker-versioned2/wiki) for the list of tags.

#### Spacial tags for daily builds

There are also special tags that are not listed in the wiki, `devel`.
The GitHub Actions workflow build and push these images daily.

- The `devel` images are based on `ubuntu:latest` (the latest Ubuntu LTS version) and install [the latest R-devel daily snapshot](https://cloud.r-project.org/src/base-prerelease/).
  pre-built `devel` images are available for `rocker/r-ver`, `rocker/rstudio`, `rocker/tidyverse`, `rocker/verse`.

#### Spacial tags for geospatial toolkit

`rocker/geospatial:dev-osgeo` is special image that differ slightly from the regular `rocker/geospatial`.

- built on the latest release of [PROJ](https://proj.org/), [GDAL](https://gdal.org/), and [GEOS](https://libgeos.org/).

## Modifying and extending images

Check [the Rocker project site](https://rocker-project.org/use/extending.html) for common methods for Rocker images.

### Install R packages

Please install R packages from source using the `install.packages()` R function or the `install2.r` script,
and use `apt` only to install necessary system libraries (e.g. `libxml2`).
Do not use `apt install r-cran-*` to install R packages.

If you would prefer to install only the latest verions of packages from pre-built binaries using `apt`,
consider using `r-base` or [`rocker/r-bspm`](https://github.com/rocker-org/bspm) instead.

### Rocker scripts

The Docker images built from this repository describe the software installation method in standalone scripts
rather than directly in the Dockerfiles.
These files are under [the `scripts` directory](./scripts/), and these files are copied in all Docker images,
under a top-level `/rocker_scripts` directory.
This allows users to extend images by selecting additional modules to install on top of any pre-built images.

For instance, if one wishes to install Shiny Server on top of a base of `rocker/rstudio:4.0.0`,
one could write a simple Dockerfile as follows:

```Dockerfile
FROM rocker/rstudio:4.0.0
RUN /rocker_scripts/install_shiny_server.sh
```

Install scripts can generally take a version as a first argument or ingest an environment variable
to specify the version to install.
So to install fixed versions, one can use either of the following syntaxes:

```Dockerfile
FROM rocker/rstudio:4.0.0
ENV SHINY_SERVER_VERSION 1.5.14.948
RUN /rocker_scripts/install_shiny_server.sh
```

```Dockerfile
FROM rocker/rstudio:4.0.0
RUN /rocker_scripts/install_shiny_server.sh 1.5.14.948
```

RStudio Server and Shiny Server are managed by [the S6 supervisor system](https://github.com/just-containers/s6-overlay),
which allows containers to manage multiple background processes gracefully.

_Note: No longer support `ADD=` runtime triggers for installing Shiny or similar modules,
which is used for R <= 3.6.3 images._

## Build images

### Container definition files

Dockerfiles and docker-bake.json files, which define the pre-built images,
are in [the `dockerfiles` folder](./dockerfiles/) and [the `bakefiles` folder](./bakefiles/).
And,
these files are generated by the build scripts under [the `build` folder](./build/).

When a new version of R or RStudio is released, GitHub Actions will automatically create a Pull Request to update these files.

### Update pre-built images

Latest R version images will be built on a rolling basis;
when the Dockerfiles are updated, they are immediately built by GitHub Actions.

Non-latest R version images will be built when a new R version is released.
At this time, a tag and a GitHub release will also be created.

## Contributing

Please check <https://github.com/rocker-org/rocker/wiki/How-to-contribute>.

## License

The Dockerfiles and the scripts in this repository are licensed under the GPL 2 or later.
