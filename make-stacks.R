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

write_stack_core <- function(r_version, ubuntu_version, cran, rstudio_version, ctan_repo) {
    template <- jsonlite::read_json("stacks/core-devel.json")

    output_path <- paste0("stacks/core-", r_version, ".json")

    template$TAG <- r_version
    # rocker/r-ver
    template$stack[[1]]$FROM <- paste0("ubuntu:", ubuntu_version)
    template$stack[[1]]$ENV$R_VERSION <- r_version
    template$stack[[1]]$ENV$CRAN <- cran
    # rocker/rstudio
    template$stack[[2]]$FROM <- paste0("rocker/r-ver:", r_version)
    template$stack[[2]]$ENV$RSTUDIO_VERSION <- rstudio_version
    # rocker/tidyverse
    template$stack[[3]]$FROM <- paste0("rocker/rstudio:", r_version)
    # rocker/verse
    template$stack[[4]]$FROM <- paste0("rocker/tidyverse:", r_version)
    template$stack[[4]]$ENV$CTAN_REPO <- ctan_repo

    jsonlite::write_json(template, output_path, pretty = TRUE, auto_unbox = TRUE)

    message(output_path)
}


df_args <- .r_versions_data(min_version = 4.0) %>%
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
    dplyr::group_by(version) %>%
    dplyr::slice_tail(n = 1) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(
        ctan_url = .latest_ctan_url(freeze_date),
        r_latest = dplyr::if_else(dplyr::row_number() == nrow(.), TRUE, FALSE)
    ) %>%
    dplyr::rename(r_version = version) %>%
    dplyr::select(!tidyselect::ends_with("_date"))

message("\nstart writing stack files.")

# Write stack core files.
devnull <- df_args %>%
    utils::tail(2) %>%
    apply(1, function(df) {
        write_stack_core(df[1], df[2], df[3], df[4], df[5])
    })

message("make-stacks.R done!\n")