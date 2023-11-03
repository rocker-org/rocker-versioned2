#!/usr/bin/env Rscript

# This script only works on Ubuntu.

library(rversions)
library(jsonlite)
library(pak)
library(dplyr, warn.conflicts = FALSE)
library(readr)
library(tibble)
library(httr)
library(purrr, warn.conflicts = FALSE)
library(glue, warn.conflicts = FALSE)
library(tidyr)
library(stringr)
library(gert)


.latest_rspm_cran_url_linux <- function(date, distro_version_name, r_version) {
  n_retry_max <- 6

  dates_try <- if (is.na(date)) {
    NA_real_
  } else {
    seq(as.Date(date), as.Date(date) - n_retry_max, by = -1)
  }

  fallback_distro <- if (distro_version_name == "jammy") {
    "focal"
  } else {
    NULL
  }

  urls_try <- tidyr::expand_grid(
    date = dates_try,
    distro_version_name = c(distro_version_name, fallback_distro),
    type = c("binary")
  ) |>
    purrr::pmap_chr(.make_rspm_cran_url_linux) |>
    unique()

  for (i in seq_along(urls_try)) {
    .url <- urls_try[i]
    if (.is_cran_url_available(.url, r_version)) break
    .url <- NA_character_
  }

  if (is.na(.url)) stop("\nCRAN mirrors are not available!\n")

  return(.url)
}

.make_rspm_cran_url_linux <- function(date, distro_version_name, type = "source") {
  base_url <- "https://p3m.dev/cran"
  .url <- dplyr::case_when(
    type == "source" & is.na(date) ~ glue::glue("{base_url}/latest"),
    type == "binary" & is.na(date) ~ glue::glue("{base_url}/__linux__/{distro_version_name}/latest"),
    type == "source" ~ glue::glue("{base_url}/{date}"),
    type == "binary" ~ glue::glue("{base_url}/__linux__/{distro_version_name}/{date}")
  )

  return(.url)
}

.is_cran_url_available <- function(.url, r_version) {
  glue::glue("\n\nfor R {r_version}, repo_ping to {.url}\n\n") |>
    cat()

  is_available <- pak::repo_ping(cran_mirror = .url, r_version = r_version, bioc = FALSE) |>
    dplyr::filter(name == "CRAN") |>
    dplyr::pull(ok)

  return(is_available)
}

.get_github_commit_date <- function(commit_url) {
  commit_date <- httr::GET(commit_url, httr::add_headers(accept = "application/vnd.github.v3+json")) |>
    httr::content() |>
    purrr::pluck("commit", "committer", "date", .default = NA) |>
    as.Date()

  commit_date
}

.is_rstudio_deb_available <- function(rstudio_version, ubuntu_series) {
  os_ver <- dplyr::case_when(
    ubuntu_series %in% c("focal") ~ "bionic",
    TRUE ~ ubuntu_series
  )

  is_available <- glue::glue(
    "https://download2.rstudio.org/server/{os_ver}/amd64/rstudio-server-{rstudio_version}-amd64.deb"
  ) |>
    stringr::str_replace_all("\\+", "-") |>
    httr::HEAD() |>
    httr::http_status() |>
    (function(x) purrr::pluck(x, "category") == "Success")()

  return(is_available)
}

.latest_ctan_url <- function(date) {
  .url <- dplyr::if_else(
    is.na(date),
    "https://mirror.ctan.org/systems/texlive/tlnet",
    stringr::str_c("https://www.texlive.info/tlnet-archive/", format(date, "%Y/%m/%d"), "/tlnet")
  )

  return(.url)
}

.cuda_baseimage_tag <- function(ubuntu_series, other_variants = "11.8.0-cudnn8-devel") {
  ubuntu_version <- dplyr::case_when(
    ubuntu_series == "focal" ~ "20.04",
    ubuntu_series == "jammy" ~ "22.04",
    ubuntu_series == "noble" ~ "24.04",
    .default = "unknown"
  )

  image_tag <- glue::glue("nvidia/cuda:{other_variants}-ubuntu{ubuntu_version}", .na = NULL)

  return(image_tag)
}

.latest_version_of_git_repo <- function(remote_repo) {
  gert::git_remote_ls(remote = remote_repo) |>
    dplyr::pull(ref) |>
    stringr::str_subset(r"(^refs/tags/v?(\d+\.){2}\d+$)") |>
    stringr::str_extract(r"((\d+\.)*\d+$)") |>
    package_version() |>
    sort() |>
    utils::tail(1) |>
    as.character()
}

.outer_paste <- function(.list) {
  .paste <- function(x, y) outer(x, y, stringr::str_c) |> c()
  out <- .list |>
    purrr::reduce(.paste)

  return(out)
}

.generate_tags <- function(base_name,
                           r_version,
                           r_minor_latest = FALSE,
                           r_major_latest = FALSE,
                           r_latest = FALSE,
                           use_latest_tag = TRUE,
                           tag_suffix = "",
                           latest_tag = "latest") {
  .tags <- .outer_paste(list(base_name, ":", r_version, tag_suffix))

  r_minor_version <- stringr::str_extract(r_version, "^\\d+\\.\\d+")
  r_major_version <- stringr::str_extract(r_version, "^\\d+")

  if (r_minor_latest == TRUE) {
    .tags <- c(.tags, .outer_paste(list(base_name, ":", r_minor_version, tag_suffix)))
  }
  if (r_major_latest == TRUE) {
    .tags <- c(.tags, .outer_paste(list(base_name, ":", r_major_version, tag_suffix)))
  }
  if (r_latest == TRUE && use_latest_tag == TRUE) {
    .tags <- c(.tags, .outer_paste(list(base_name, ":", latest_tag)))
  }

  return(as.list(.tags))
}


write_stack <- function(r_version,
                        ubuntu_series,
                        cran,
                        rstudio_version,
                        ctan_url,
                        r_minor_latest = FALSE,
                        r_major_latest = FALSE,
                        r_latest = FALSE) {
  template <- jsonlite::read_json("stacks/devel.json")

  output_path <- stringr::str_c("stacks/", r_version, ".json")

  template$TAG <- r_version

  template$group <- list(c(list(
    default = list(c(list(targets = c(
      "r-ver",
      "rstudio",
      "tidyverse",
      "verse",
      "geospatial",
      "shiny",
      "shiny-verse",
      "binder"
    )))),
    cuda11images = list(c(list(targets = c(
      "cuda",
      "ml",
      "ml-verse"
    ))))
  )))

  # rocker/r-ver
  template$stack[[1]]$FROM <- stringr::str_c("ubuntu:", ubuntu_series)
  template$stack[[1]]$tags <- .generate_tags(
    c("docker.io/rocker/r-ver", "ghcr.io/rocker-org/r-ver"),
    r_version,
    r_minor_latest,
    r_major_latest,
    r_latest
  )
  template$stack[[1]]$ENV$R_VERSION <- r_version
  template$stack[[1]]$ENV_after_a_script$CRAN <- cran
  template$stack[[1]]$platforms <- list("linux/amd64", "linux/arm64")
  template$stack[[1]]$`cache-from` <- list(stringr::str_c("docker.io/rocker/r-ver:", r_version))
  template$stack[[1]]$`cache-to` <- list("type=inline")

  # rocker/rstudio
  template$stack[[2]]$FROM <- stringr::str_c("rocker/r-ver:", r_version)
  template$stack[[2]]$tags <- .generate_tags(
    c("docker.io/rocker/rstudio", "ghcr.io/rocker-org/rstudio"),
    r_version,
    r_minor_latest,
    r_major_latest,
    r_latest
  )
  template$stack[[2]]$ENV$RSTUDIO_VERSION <- rstudio_version
  template$stack[[2]]$platforms <-
    # linux/arm64 platform version of RStudio IDE will bundle Quarto CLI after version 2023.05.0
    # (https://github.com/rstudio/rstudio/issues/12411)
    # We are postponing the build of the linux/arm64 version of rocker/rstudio until this version
    # because we want to fix the version of Quarto CLI included in rocker/rstudio
    if (numeric_version(stringr::str_replace_all(rstudio_version, r"(\+)", ".")) > "2023.05.0") {
      list("linux/amd64", "linux/arm64")
    }

  # rocker/tidyverse
  template$stack[[3]]$FROM <- stringr::str_c("rocker/rstudio:", r_version)
  template$stack[[3]]$tags <- .generate_tags(
    c("docker.io/rocker/tidyverse", "ghcr.io/rocker-org/tidyverse"),
    r_version,
    r_minor_latest,
    r_major_latest,
    r_latest
  )

  # rocker/verse
  template$stack[[4]]$FROM <- stringr::str_c("rocker/tidyverse:", r_version)
  template$stack[[4]]$tags <- .generate_tags(
    c("docker.io/rocker/verse", "ghcr.io/rocker-org/verse"),
    r_version,
    r_minor_latest,
    r_major_latest,
    r_latest
  )
  template$stack[[4]]$ENV$CTAN_REPO <- ctan_url

  # rocker/geospatial
  template$stack[[5]]$FROM <- stringr::str_c("rocker/verse:", r_version)
  template$stack[[5]]$tags <- .generate_tags(
    c("docker.io/rocker/geospatial", "ghcr.io/rocker-org/geospatial"),
    r_version,
    r_minor_latest,
    r_major_latest,
    r_latest
  )

  # rocker/shiny
  template$stack[[6]]$FROM <- stringr::str_c("rocker/r-ver:", r_version)
  template$stack[[6]]$tags <- .generate_tags(
    c("docker.io/rocker/shiny", "ghcr.io/rocker-org/shiny"),
    r_version,
    r_minor_latest,
    r_major_latest,
    r_latest
  )

  # rocker/shiny-verse
  template$stack[[7]]$FROM <- stringr::str_c("rocker/shiny:", r_version)
  template$stack[[7]]$tags <- .generate_tags(
    c("docker.io/rocker/shiny-verse", "ghcr.io/rocker-org/shiny-verse"),
    r_version,
    r_minor_latest,
    r_major_latest,
    r_latest
  )

  # rocker/binder
  template$stack[[8]]$FROM <- stringr::str_c("rocker/geospatial:", r_version)
  template$stack[[8]]$tags <- .generate_tags(
    c("docker.io/rocker/binder", "ghcr.io/rocker-org/binder"),
    r_version,
    r_minor_latest,
    r_major_latest,
    r_latest
  )

  # rocker/cuda:X.Y.Z
  template$stack[[9]]$FROM <- .cuda_baseimage_tag(ubuntu_series)
  template$stack[[9]]$tags <- c(
    .generate_tags(
      c("docker.io/rocker/cuda", "ghcr.io/rocker-org/cuda"),
      r_version,
      r_minor_latest,
      r_major_latest,
      r_latest
    )
  )
  template$stack[[9]]$ENV$R_VERSION <- r_version
  template$stack[[9]]$ENV_after_a_script$CRAN <- cran
  template$stack[[9]]$`cache-from` <- list(stringr::str_c("docker.io/rocker/cuda:", r_version))
  template$stack[[9]]$`cache-to` <- list("type=inline")

  # rocker/ml:X.Y.Z
  template$stack[[10]]$FROM <- stringr::str_c("rocker/cuda:", r_version)
  template$stack[[10]]$tags <- c(
    .generate_tags(
      c("docker.io/rocker/ml", "ghcr.io/rocker-org/ml"),
      r_version,
      r_minor_latest,
      r_major_latest,
      r_latest
    )
  )
  template$stack[[10]]$ENV$RSTUDIO_VERSION <- rstudio_version

  # rocker/ml-verse:X.Y.Z
  template$stack[[11]]$FROM <- stringr::str_c("rocker/ml:", r_version)
  template$stack[[11]]$tags <- c(
    .generate_tags(
      c("docker.io/rocker/ml-verse", "ghcr.io/rocker-org/ml-verse"),
      r_version,
      r_minor_latest,
      r_major_latest,
      r_latest
    )
  )
  template$stack[[11]]$ENV$CTAN_REPO <- ctan_url

  jsonlite::write_json(template, output_path, pretty = TRUE, auto_unbox = TRUE)

  message(output_path)
}


# R versions data from the main R SVN repository.
df_r <- rversions::r_versions() |>
  dplyr::transmute(
    r_version = version,
    r_release_date = as.Date(date),
    r_freeze_date = dplyr::lead(r_release_date, 1) - 1
  ) |>
  dplyr::filter(package_version(r_version) >= package_version("4.0.0")) |>
  dplyr::arrange(r_release_date)

# Ubuntu versions data from the Ubuntu local csv file.
df_ubuntu_lts <- suppressWarnings(
  readr::read_csv("/usr/share/distro-info/ubuntu.csv", show_col_types = FALSE) |>
    dplyr::filter(stringr::str_detect(version, "LTS")) |>
    dplyr::transmute(
      ubuntu_version = stringr::str_extract(version, "^\\d+\\.\\d+"),
      ubuntu_series = series,
      ubuntu_release_date = release
    ) |>
    dplyr::arrange(ubuntu_release_date)
)

# RStudio versions data from the RStudio GitHub repository.
df_rstudio <- gert::git_remote_ls(remote = "https://github.com/rstudio/rstudio.git") |>
  dplyr::filter(stringr::str_detect(ref, "^refs/tags/v")) |>
  dplyr::mutate(
    rstudio_version = stringr::str_extract(ref, r"(\d+\.\d+\.\d+.{0,1}\d*)"),
    commit_url = glue::glue("https://api.github.com/repos/rstudio/rstudio/commits/{oid}"),
    .keep = "none"
  ) |>
  dplyr::slice_tail(n = 10) |>
  dplyr::rowwise() |>
  dplyr::mutate(rstudio_commit_date = .get_github_commit_date(commit_url)) |>
  dplyr::ungroup() |>
  tidyr::drop_na() |>
  dplyr::select(
    rstudio_version,
    rstudio_commit_date
  ) |>
  dplyr::arrange(rstudio_commit_date)


df_args <- df_r |>
  tidyr::expand_grid(df_ubuntu_lts) |>
  dplyr::filter(r_release_date >= ubuntu_release_date + 90) |>
  dplyr::group_by(r_version) |>
  dplyr::slice_max(ubuntu_release_date, with_ties = FALSE) |>
  dplyr::ungroup() |>
  (function(x) {
    cat("\nPing to the RSPM CRAN mirrors...\n")
    return(x)
  })() |>
  dplyr::rowwise() |>
  dplyr::mutate(
    cran = .latest_rspm_cran_url_linux(r_freeze_date, ubuntu_series, r_version)
  ) |>
  dplyr::ungroup() |>
  tidyr::expand_grid(df_rstudio) |>
  dplyr::filter(r_freeze_date > rstudio_commit_date | is.na(r_freeze_date)) |>
  dplyr::rowwise() |>
  dplyr::filter(.is_rstudio_deb_available(rstudio_version, ubuntu_series)) |>
  dplyr::ungroup() |>
  dplyr::group_by(r_version, ubuntu_series) |>
  dplyr::slice_max(rstudio_version, with_ties = FALSE) |>
  dplyr::ungroup() |>
  dplyr::group_by(r_minor_version = stringr::str_extract(r_version, "^\\d+\\.\\d+")) |>
  dplyr::mutate(r_minor_latest = dplyr::if_else(dplyr::row_number() == dplyr::n(), TRUE, FALSE)) |>
  dplyr::ungroup() |>
  dplyr::group_by(r_major_version = stringr::str_extract(r_version, "^\\d+")) |>
  dplyr::mutate(r_major_latest = dplyr::if_else(dplyr::row_number() == dplyr::n(), TRUE, FALSE)) |>
  dplyr::ungroup() |>
  dplyr::mutate(
    ctan_url = .latest_ctan_url(r_freeze_date),
    r_latest = dplyr::if_else(dplyr::row_number() == dplyr::n(), TRUE, FALSE)
  )


r_latest_version <- df_args$r_version |>
  package_version() |>
  max() |>
  as.character()
rstudio_latest_version <- df_args |>
  dplyr::slice_max(rstudio_commit_date, with_ties = FALSE) |>
  dplyr::pull(rstudio_version)

message(stringr::str_c("\nThe latest R version is ", r_latest_version))
message(stringr::str_c("The latest RStudio version is ", rstudio_latest_version))

message("\nstart writing stack files.")

# Update the template, devel.json
template <- jsonlite::read_json("stacks/devel.json")
# Copy S6_VERSION from rocker/rstudio to others.
## rocker/shiny
template$stack[[6]]$ENV$S6_VERSION <- template$stack[[2]]$ENV$S6_VERSION
## rocker/ml
template$stack[[10]]$ENV$S6_VERSION <- template$stack[[2]]$ENV$S6_VERSION
# Update the RStudio Server Version.
## rocker/rstudio
template$stack[[2]]$ENV$RSTUDIO_VERSION <- rstudio_latest_version
## rocker/ml
template$stack[[10]]$ENV$RSTUDIO_VERSION <- rstudio_latest_version

# Update the cuda base image
template$stack[[9]]$FROM <- .cuda_baseimage_tag(dplyr::last(df_ubuntu_lts$ubuntu_series))

jsonlite::write_json(template, "stacks/devel.json", pretty = TRUE, auto_unbox = TRUE)
message("stacks/devel.json")


# Update core-latest-daily
latest_daily <- jsonlite::read_json("stacks/core-latest-daily.json")
## Only rstudio, tidyverse, verse
latest_daily$stack <- template$stack[2:4]
latest_daily$stack[[1]]$FROM <- "rocker/r-ver:latest"
latest_daily$stack[[1]]$ENV$RSTUDIO_VERSION <- "daily"
latest_daily$stack[[1]]$platforms <- list("linux/amd64", "linux/arm64")
latest_daily$stack[[2]]$FROM <- "rocker/rstudio:latest-daily"
latest_daily$stack[[3]]$FROM <- "rocker/tidyverse:latest-daily"

jsonlite::write_json(latest_daily, "stacks/core-latest-daily.json", pretty = TRUE, auto_unbox = TRUE)
message("stacks/core-latest-daily.json")


# Update the extra stack
extra <- jsonlite::read_json("stacks/extra.json")
extra$TAG <- r_latest_version
## geospatial-ubuntugis
extra$stack[[1]]$FROM <- stringr::str_c("rocker/verse:", r_latest_version)
extra$stack[[1]]$tags <- .generate_tags(
  c("docker.io/rocker/geospatial", "ghcr.io/rocker-org/geospatial"),
  r_latest_version,
  r_minor_latest = FALSE,
  r_major_latest = FALSE,
  r_latest = TRUE,
  use_latest_tag = TRUE,
  latest_tag = "ubuntugis",
  tag_suffix = "-ubuntugis"
)
## geospatial-dev-osgeo
extra$stack[[2]]$FROM <- stringr::str_c("rocker/verse:", r_latest_version)
extra$stack[[2]]$tags <- stringr::str_c(
  c("docker.io/rocker/", "ghcr.io/rocker-org/"), "geospatial:dev-osgeo"
)
extra$stack[[2]]$ENV$PROJ_VERSION <- .latest_version_of_git_repo("https://github.com/OSGeo/PROJ.git")
extra$stack[[2]]$ENV$GDAL_VERSION <- .latest_version_of_git_repo("https://github.com/OSGeo/gdal.git")
extra$stack[[2]]$ENV$GEOS_VERSION <- .latest_version_of_git_repo("https://github.com/libgeos/geos.git")

jsonlite::write_json(extra, "stacks/extra.json", pretty = TRUE, auto_unbox = TRUE)
message("stacks/extra.json")


# Write latest two stack files.
df_args |>
  dplyr::group_by(r_version) |>
  dplyr::slice_tail(n = 1) |>
  dplyr::ungroup() |>
  dplyr::slice_max(r_release_date, n = 2, with_ties = FALSE) |>
  dplyr::select(
    r_version,
    ubuntu_series,
    cran,
    rstudio_version,
    ctan_url,
    r_minor_latest,
    r_major_latest,
    r_latest
  ) |>
  purrr::pwalk(write_stack)

message("make-stacks.R done!\n")
