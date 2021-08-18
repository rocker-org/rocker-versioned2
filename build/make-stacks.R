#!/usr/bin/env Rscript

# This script only works on Ubuntu.
# This script needs development version of pak package (>=0.1.2.9001).

library(rversions)
library(jsonlite)
library(pak)
library(dplyr)
library(readr)
library(httr)
library(purrr)
library(glue)
library(tidyr)
library(tidyselect)
library(stringr)


.r_versions_data <- function(min_version) {
  data <- rversions::r_versions() %>%
    dplyr::mutate(
      release_date = as.Date(date),
      freeze_date = dplyr::lead(release_date, 1) - 1
    ) %>%
    dplyr::filter(readr::parse_number(version) >= min_version) %>%
    dplyr::select(version, release_date, freeze_date) %>%
    dplyr::rowwise() %>%
    dplyr::mutate(ubuntu_codename = .latest_ubuntu_lts_series(release_date)) %>%
    dplyr::ungroup()

  return(data)
}

.latest_ubuntu_lts_series <- function(date) {
  data <- utils::read.csv("/usr/share/distro-info/ubuntu.csv", stringsAsFactors = FALSE) %>%
    dplyr::filter(
      as.Date(release) < as.Date(date),
      version %in% grep("LTS", version, value = TRUE)
    ) %>%
    utils::tail(1)

  return(data$series)
}

.latest_rspm_cran_url_linux <- function(date, distro_version_name) {
  n_retry_max <- 6
  if (is.na(date)) {
    url <- .make_rspm_cran_url_linux(date, distro_version_name)
    if (.is_cran_url_available(url) != TRUE) url <- NA_character_
  } else {
    dates <- seq(as.Date(date), as.Date(date) - n_retry_max, by = -1)
    for (i in seq_len(length(dates))) {
      url <- .make_rspm_cran_url_linux(dates[i], distro_version_name)
      if (.is_cran_url_available(url) == TRUE) break
      url <- NA_character_
    }
  }
  return(url)
}

.make_rspm_cran_url_linux <- function(date, distro_version_name) {
  if (is.na(date)) {
    url <- paste("https://packagemanager.rstudio.com/all/__linux__", distro_version_name, "latest", sep = "/")
  } else {
    url <- paste("https://packagemanager.rstudio.com/cran/__linux__", distro_version_name, date, sep = "/")
  }
  return(url)
}

.is_cran_url_available <- function(url) {
  repo_data <- pak::repo_ping(cran_mirror = url, bioc = FALSE)
  return(repo_data[repo_data$name == "CRAN", ]$ok)
}

.get_github_commit_date <- function(url) {
  httr::GET(url, httr::add_headers(accept = "application/vnd.github.v3+json")) %>%
    httr::content() %>%
    purrr::pluck("commit", "committer", "date") %>%
    as.Date()
}

rstudio_versions <- function(n_versions = 10) {
  data <- httr::GET(
    "https://api.github.com/repos/rstudio/rstudio/tags",
    httr::add_headers(accept = "application/vnd.github.v3+json"),
    query = list(per_page = n_versions)
  ) %>%
    httr::content() %>%
    {
      data.frame(
        rstudio_version = purrr::map_chr(., "name") %>% substring(2),
        commit_url = purrr::map_chr(., c("commit", "url"))
      )
    } %>%
    dplyr::rowwise() %>%
    dplyr::mutate(commit_date = .get_github_commit_date(commit_url)) %>%
    dplyr::ungroup() %>%
    dplyr::select(!commit_url) %>%
    dplyr::arrange(commit_date)

  return(data)
}

.is_rstudio_deb_url <- function(rstudio_version, ubuntu_codename) {
  os_ver <- dplyr::case_when(
    ubuntu_codename %in% c("bionic", "focal") ~ "bionic",
    ubuntu_codename %in% c("xenial") ~ "xenial"
  )

  is_available <- glue::glue(
    "https://s3.amazonaws.com/rstudio-ide-build/server/{os_ver}/amd64/rstudio-server-{rstudio_version}-amd64.deb"
  ) %>%
    httr::HEAD() %>%
    httr::http_status() %>%
    purrr::pluck("category") %>%
    {
      ifelse(. == "Success", TRUE, FALSE)
    }

  return(is_available)
}

.latest_ctan_url <- function(date) {
  url <- dplyr::if_else(
    is.na(date),
    "http://mirror.ctan.org/systems/texlive/tlnet",
    paste0("http://www.texlive.info/tlnet-archive/", format(date, "%Y/%m/%d"), "/tlnet")
  )
  return(url)
}


.generate_tags <- function(base_name,
                           r_version,
                           r_minor_latest = FALSE,
                           r_major_latest = FALSE,
                           r_latest = FALSE,
                           use_latest_tag = TRUE,
                           tag_suffix = "",
                           latest_tag = "latest") {
  list_tags <- list(paste0(base_name, ":", r_version, tag_suffix))

  r_minor_version <- stringr::str_extract(r_version, "^\\d+\\.\\d+")
  r_major_version <- stringr::str_extract(r_version, "^\\d+")

  if (r_minor_latest == TRUE) list_tags <- c(list_tags, list(paste0(base_name, ":", r_minor_version, tag_suffix)))
  if (r_major_latest == TRUE) list_tags <- c(list_tags, list(paste0(base_name, ":", r_major_version, tag_suffix)))
  if (r_latest == TRUE & use_latest_tag == TRUE) list_tags <- c(list_tags, list(paste0(base_name, ":", latest_tag)))

  return(list_tags)
}


write_stack <- function(r_version,
                        ubuntu_version,
                        cran,
                        rstudio_version,
                        ctan_repo,
                        r_minor_latest = FALSE,
                        r_major_latest = FALSE,
                        r_latest = FALSE) {
  template <- jsonlite::read_json("stacks/devel.json")

  output_path <- paste0("stacks/", r_version, ".json")

  template$TAG <- r_version

  # rocker/r-ver
  template$stack[[1]]$FROM <- paste0("ubuntu:", ubuntu_version)
  template$stack[[1]]$tags <- .generate_tags(
    "docker.io/rocker/r-ver",
    r_version,
    r_minor_latest,
    r_major_latest,
    r_latest
  )
  template$stack[[1]]$ENV$R_VERSION <- r_version
  template$stack[[1]]$ENV$CRAN <- cran

  # rocker/rstudio
  template$stack[[2]]$FROM <- paste0("rocker/r-ver:", r_version)
  template$stack[[2]]$tags <- .generate_tags(
    "docker.io/rocker/rstudio",
    r_version,
    r_minor_latest,
    r_major_latest,
    r_latest
  )
  template$stack[[2]]$ENV$RSTUDIO_VERSION <- rstudio_version

  # rocker/tidyverse
  template$stack[[3]]$FROM <- paste0("rocker/rstudio:", r_version)
  template$stack[[3]]$tags <- .generate_tags(
    "docker.io/rocker/tidyverse",
    r_version,
    r_minor_latest,
    r_major_latest,
    r_latest
  )

  # rocker/verse
  template$stack[[4]]$FROM <- paste0("rocker/tidyverse:", r_version)
  template$stack[[4]]$tags <- .generate_tags(
    "docker.io/rocker/verse",
    r_version,
    r_minor_latest,
    r_major_latest,
    r_latest
  )
  template$stack[[4]]$ENV$CTAN_REPO <- ctan_repo

  # rocker/geospatial
  template$stack[[5]]$FROM <- paste0("rocker/verse:", r_version)
  template$stack[[5]]$tags <- .generate_tags(
    "docker.io/rocker/geospatial",
    r_version,
    r_minor_latest,
    r_major_latest,
    r_latest
  )

  # rocker/shiny
  template$stack[[6]]$FROM <- paste0("rocker/r-ver:", r_version)
  template$stack[[6]]$tags <- .generate_tags(
    "docker.io/rocker/shiny",
    r_version,
    r_minor_latest,
    r_major_latest,
    r_latest
  )

  # rocker/shiny-verse
  template$stack[[7]]$FROM <- paste0("rocker/shiny:", r_version)
  template$stack[[7]]$tags <- .generate_tags(
    "docker.io/rocker/shiny-verse",
    r_version,
    r_minor_latest,
    r_major_latest,
    r_latest
  )

  # rocker/binder
  template$stack[[8]]$FROM <- paste0("rocker/geospatial:", r_version)
  template$stack[[8]]$tags <- .generate_tags("docker.io/rocker/binder", r_version, r_minor_latest, r_major_latest, r_latest)

  # rocker/r-ver:X.Y.Z-cuda10.1
  template$stack[[9]]$FROM <- paste0("rocker/r-ver:", r_version)
  template$stack[[9]]$tags <- c(
    .generate_tags(
      "docker.io/rocker/cuda",
      r_version,
      r_minor_latest,
      r_major_latest,
      r_latest,
      use_latest_tag = TRUE,
      latest_tag = "cuda10.1",
      tag_suffix = "-cuda10.1"
    ),
    .generate_tags(
      "docker.io/rocker/cuda",
      r_version,
      r_minor_latest,
      r_major_latest,
      r_latest
    ),
    list(paste0("docker.io/rocker/r-ver:", r_version, "-cuda10.1"))
  )

  # rocker/ml:X.Y.Z-cuda10.1
  template$stack[[10]]$FROM <- paste0("rocker/cuda:", r_version)
  template$stack[[10]]$tags <- c(
    .generate_tags(
      "docker.io/rocker/ml",
      r_version,
      r_minor_latest,
      r_major_latest,
      r_latest,
      use_latest_tag = TRUE,
      latest_tag = "cuda10.1",
      tag_suffix = "-cuda10.1"
    ),
    .generate_tags(
      "docker.io/rocker/ml",
      r_version,
      r_minor_latest,
      r_major_latest,
      r_latest
    )
  )
  template$stack[[10]]$ENV$RSTUDIO_VERSION <- rstudio_version

  # rocker/ml-verse:X.Y.Z-cuda10.1
  template$stack[[11]]$FROM <- paste0("rocker/ml:", r_version)
  template$stack[[11]]$tags <- c(
    .generate_tags(
      "docker.io/rocker/ml-verse",
      r_version,
      r_minor_latest,
      r_major_latest,
      r_latest,
      use_latest_tag = TRUE,
      latest_tag = "cuda10.1",
      tag_suffix = "-cuda10.1"
    ),
    .generate_tags(
      "docker.io/rocker/ml-verse",
      r_version,
      r_minor_latest,
      r_major_latest,
      r_latest
    )
  )
  template$stack[[11]]$ENV$CTAN_REPO <- ctan_repo

  jsonlite::write_json(template, output_path, pretty = TRUE, auto_unbox = TRUE)

  message(output_path)
}



df_args <- .r_versions_data(min_version = 4.0) %>%
  dplyr::rename(r_version = version) %>%
  dplyr::rowwise() %>%
  dplyr::mutate(
    cran = .latest_rspm_cran_url_linux(freeze_date, ubuntu_codename),
  ) %>%
  dplyr::ungroup() %>%
  tidyr::expand_grid(rstudio_versions(n_versions = 10)) %>%
  dplyr::filter(freeze_date > commit_date | is.na(freeze_date)) %>%
  dplyr::rowwise() %>%
  dplyr::filter(.is_rstudio_deb_url(rstudio_version, ubuntu_codename)) %>%
  dplyr::ungroup() %>%
  dplyr::group_by(r_version) %>%
  dplyr::slice_tail(n = 1) %>%
  dplyr::group_by(r_minor_version = stringr::str_extract(r_version, "^\\d+\\.\\d+")) %>%
  dplyr::mutate(r_minor_latest = dplyr::if_else(dplyr::row_number() == dplyr::n(), TRUE, FALSE)) %>%
  dplyr::ungroup() %>%
  dplyr::group_by(r_major_version = stringr::str_extract(r_version, "^\\d+")) %>%
  dplyr::mutate(r_major_latest = dplyr::if_else(dplyr::row_number() == dplyr::n(), TRUE, FALSE)) %>%
  dplyr::ungroup() %>%
  dplyr::mutate(
    ctan_url = .latest_ctan_url(freeze_date),
    r_latest = dplyr::if_else(dplyr::row_number() == dplyr::n(), TRUE, FALSE)
  )

# Write json file for GitHubActions build matrix.
df_args %>%
  dplyr::select(r_version, r_latest) %>%
  {
    jsonlite::write_json(
      list(include = .),
      "build/matrix/all.json",
      pretty = TRUE,
      auto_unbox = TRUE
    )
    jsonlite::write_json(
      list(include = utils::tail(., 1)),
      "build/matrix/latest.json",
      pretty = TRUE,
      auto_unbox = TRUE
    )
  }


message("\nstart writing stack files.")

# Update the RStudio Server Version in the devel stack file.
template <- jsonlite::read_json("stacks/devel.json")
template$stack[[2]]$ENV$RSTUDIO_VERSION <- dplyr::last(df_args$rstudio_version)
jsonlite::write_json(template, "stacks/devel.json", pretty = TRUE, auto_unbox = TRUE)
message("stacks/devel.json")

# Write stack core files.
devnull <- df_args %>%
  utils::tail(2) %>%
  dplyr::select(
    r_version,
    ubuntu_codename,
    cran,
    rstudio_version,
    ctan_url,
    r_minor_latest,
    r_major_latest,
    r_latest
  ) %>%
  apply(1, function(df) {
    write_stack(df[1], df[2], df[3], df[4], df[5], df[6], df[7], df[8])
  })

message("make-stacks.R done!\n")
