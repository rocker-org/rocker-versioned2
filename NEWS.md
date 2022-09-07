# News

## 2022-09

### Changes in pre-built images

- RStudio Server user settings are written to `~/.config/rstudio/rstudio-prefs.json`, not `~/.rstudio/monitored/user-settings/user-settings`.
  ([#63](https://github.com/rocker-org/rocker-versioned2/issues/63))

## 2022-07

### Changes in rocker_scripts

- `install_binder.sh` is renamed to `install_jupyter.sh`.
  ([#494](https://github.com/rocker-org/rocker-versioned2/pull/494))
- `install_python.sh` no longer installs pyenv.
  ([#494](https://github.com/rocker-org/rocker-versioned2/pull/494))
- Update `install_quarto.sh` for the first stable release of quarto cli.
  ([#506](https://github.com/rocker-org/rocker-versioned2/pull/506))
  - The default behavior of `install_quarto.sh` has been changed so that if quarto bundled with RStudio is detected,
    it will use the quarto cli bundled with RStudio instead of installing quarto cli.
  - Specifying `./install_quarto.sh prerelease` now installs the latest prerelease version of quarto cli.

### Changes in pre-built images

- `rocker/binder`, `rocker/cuda`, `rocker/ml` and `rocker/ml-verse` no longer configure a default python venv and
  no longer installs pyenv.
  ([#494](https://github.com/rocker-org/rocker-versioned2/pull/494))
- Update to address RStudio Server now bundling stable release version of quarto cli.
  ([#506](https://github.com/rocker-org/rocker-versioned2/pull/506))
  - New builds of `rocker/verse` and `rocker/ml-verse` for 4.1.0 <= R <= 4.2.0 will install quarto cli version 1.0.36.
  - New builds of `rocker/rstudio` and `rocker/ml` for R >= 4.2.1 (with RStudio Server v2022.07.1+554 or later)
    will be configured to use the quarto cli bundled with RStudio Server system-wide.

## 2022-06

### Changes in rocker_scripts

- `install_quarto.sh` was changed to not install R packages and only install quarto cli.
  ([#487](https://github.com/rocker-org/rocker-versioned2/pull/487))

### Changes in pre-built images

- New builds of `rocker/verse` and `rocker/ml-verse` for R >= 4.1.0 no longer install the quarto R package.
  ([#487](https://github.com/rocker-org/rocker-versioned2/pull/487))

## 2022-05

### Changes in rocker_scripts

- Installation scripts are now tested in GitHub Actions.
  ([#411](https://github.com/rocker-org/rocker-versioned2/pull/441))

### Changes in pre-built images

- Newly built images are now pushed to the GitHub Container Registry as well as DockerHub.
  They can be used by specifying the name as `ghcr.io/rocker-org/rocker/r-ver:4`.
  ([#456](https://github.com/rocker-org/rocker-versioned2/pull/456))

## 2022-04

### Changes in pre-built images

- R 4.0.0 images built on Ubuntu 18.04 (`rocker/r-ver:4.0.0-ubuntu18.04`, `rocker/rstudio:4.0.0-ubuntu18.04`,
  `rocker/tidyverse:4.0.0-ubuntu18.04`, `rocker/verse:4.0.0-ubuntu18.04`, `rocker/geospatial:4.0.0-ubuntu18.04`)
  are no longer built. The last builds of these images were created on 2022-03-10.
  ([#432](https://github.com/rocker-org/rocker-versioned2/issues/432))

## 2022-03

### Changes in rocker_scripts

- `install_R.sh` was split into two scripts, `install_R_source.sh` and `setup_R.sh`. ([#386](https://github.com/rocker-org/rocker-versioned2/pull/386))
- `patch_install_command.sh` was merged into `setup_R.sh`. ([#386](https://github.com/rocker-org/rocker-versioned2/pull/386))

### Changes in pre-built images

- Fixed the BLAS hot-switching mechanism.
  The image size has increased by approximately 30 MB with the new `liblapack-dev` installation.
  ([#386](https://github.com/rocker-org/rocker-versioned2/pull/386), [#390](https://github.com/rocker-org/rocker-versioned2/issues/390))

## 2022-01

### Changes in rocker_scripts

- `userconf.sh`, which is executed when RStudio Server is launched, has been split into `init_set_env.sh` and `init_userconf.sh`.
  `init_set_env.sh` is also executed when Shiny Server is launched.
  ([#320](https://github.com/rocker-org/rocker-versioned2/pull/320))

### Changes in pre-built images

- Environment variables set in the container are now reflected in the sessions on Shiny Server. ([#320](https://github.com/rocker-org/rocker-versioned2/pull/320))
- Change the date of the CRAN mirrors that were set for the R 4.0.0, R 4.0.1, R 4.0.2, and R 4.0.3 images.
  This reconfiguration was done mechanically, selecting the mirrors just before the release date of the next version of R.
  ([#328](https://github.com/rocker-org/rocker-versioned2/pull/328))
  - R 4.0.0: 2020-06-08 to 2020-06-04 (The next version, R 4.0.1 was released on 2020-06-06)
  - R 4.0.1: 2020-06-25 to 2020-06-18 (The next version, R 4.0.2 was released on 2020-06-22)
  - R 4.0.2: 2020-10-07 to 2020-10-09 (The next version, R 4.0.3 was released on 2020-10-10)
  - R 4.0.3: 2021-02-17 to 2021-02-11 (The next version, R 4.0.4 was released on 2021-02-15)

## 2021-12

### Changes in pre-built images

- In the newly built images, the default password for RStudio Server will be randomly generated when the server is started.
  ([#298](https://github.com/rocker-org/rocker-versioned2/pull/298))

### Changes in rocker_scripts

- The default locale, `LANG=en_US.UTF-8`,
  is now set [as recommended](https://github.com/docker-library/docs/tree/master/ubuntu#locales) by the official ubuntu image.
  ([#302](https://github.com/rocker-org/rocker-versioned2/issues/302), [#313](https://github.com/rocker-org/rocker-versioned2/pull/313))

## 2021-11

### Changes in rocker_scripts

- `install_tidyverse.sh` now assumes that the `install2.r` command has the `--skipmissing` option. ([#283](https://github.com/rocker-org/rocker-versioned2/pull/283))
- The [duckdb](https://github.com/duckdb/duckdb) package is added to the R packages installed by running `install_tidyverse.sh`.
  ([#283](https://github.com/rocker-org/rocker-versioned2/pull/283))

### Changes in pre-built images

- New builds of `rocker/tidyverse`, `rocker/shiny-verse`, `rocker/ml` for R >= 4.0.2 will install the duckdb R package. ([#283](https://github.com/rocker-org/rocker-versioned2/pull/283))

## 2021-10

### Changes in rocker_scripts

- Add a new script `install_quarto.sh`,
  to install [quarto-cli](https://github.com/quarto-dev/quarto-cli) and the quarto R package.
  ([#253](https://github.com/rocker-org/rocker-versioned2/pull/253))
- Add a new script `install_julia.sh`, to install the Julia Language and two R packages which call Julia from R;
  [JuliaCall](https://github.com/Non-Contradiction/JuliaCall) and [JuliaConnectoR](https://github.com/stefan-m-lenz/JuliaConnectoR).
  ([#269](https://github.com/rocker-org/rocker-versioned2/pull/269))
- A new script `install2.r`, copied from [eddelbuettel/littler](https://github.com/eddelbuettel/littler) and slightly modified,
  has been added in the `bin` directory. And add a new script `patch_install_command.sh`,
  to replace the symbolic link of `install2.r` command with rocker script version of `install2.r`.
  ([#275](https://github.com/rocker-org/rocker-versioned2/pull/275))
- `install2.r` gets a new option `--skipmissing`. ([#275](https://github.com/rocker-org/rocker-versioned2/pull/275))

### Changes in pre-built images

- New builds of `rocker/verse` and `rocker/ml-verse` for R >= 4.1.0 will install [quarto-cli](https://github.com/quarto-dev/quarto-cli)
  and the quarto R package.
  ([#253](https://github.com/rocker-org/rocker-versioned2/pull/253))
- The `install2.r` command has been replaced by rocker scripts version of `install2.r`. ([#275](https://github.com/rocker-org/rocker-versioned2/pull/275))

## 2021-06

### Changes in pre-built images

- The time zone setting for R, which was hardcoded as `TZ=Etc/UTC` in `Renviron.site`, has been removed.
  The environment variable `TZ` set in the container will be used instead.
  ([#151](https://github.com/rocker-org/rocker-versioned2/issues/151), [#186](https://github.com/rocker-org/rocker-versioned2/pull/186))
- Environment variables set in the container are now reflected in the sessions on RStudio Server.
  ([#186](https://github.com/rocker-org/rocker-versioned2/pull/186),
  [#189](https://github.com/rocker-org/rocker-versioned2/pull/189),
  [#190](https://github.com/rocker-org/rocker-versioned2/pull/190))
