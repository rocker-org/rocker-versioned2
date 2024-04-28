#' Get R versions table
#' @param min_version A single character of minimum R version like `"4.0.0"`.
#' @return A [tibble::tibble] of R versions.
#' - r_version: Character, R version. e.g. `"4.0.0"`.
#' - r_release_date: Date, R release date.
#' - r_freeze_date: Date, The date before the next R release.
#' @examples
#' r_versions_with_freeze_dates()
r_versions_with_freeze_dates <- function(min_version = "4.0.0") {
  rversions::r_versions() |>
    tibble::as_tibble() |>
    dplyr::mutate(
      r_version = version,
      r_release_date = as.Date(date),
      r_freeze_date = dplyr::lead(r_release_date, 1) - 1,
      .keep = "none"
    ) |>
    dplyr::filter(package_version(r_version) >= package_version(min_version)) |>
    dplyr::arrange(r_release_date)
}


#' Get Ubuntu LTS versions table
#' @return A [tibble::tibble] of Ubuntu LTS versions.
#' - ubuntu_version: Character, Ubuntu version. e.g. `"20.04"`.
#' - ubuntu_series: Character, Ubuntu series. e.g. `"focal"`.
#' - ubuntu_release_date: Date, Ubuntu release date.
#' @examples
#' ubuntu_lts_versions()
ubuntu_lts_versions <- function() {
  # On Ubuntu, the local file `/usr/share/distro-info/ubuntu.csv` is the same.
  readr::read_csv(
    "https://git.launchpad.net/ubuntu/+source/distro-info-data/plain/ubuntu.csv",
    show_col_types = FALSE
  ) |>
    suppressWarnings() |>
    dplyr::filter(stringr::str_detect(version, "LTS")) |>
    dplyr::mutate(
      ubuntu_version = stringr::str_extract(version, "^\\d+\\.\\d+"),
      ubuntu_series = series,
      ubuntu_release_date = release,
      .keep = "none"
    ) |>
    dplyr::arrange(ubuntu_release_date)
}


#' Get RSutdio IDE versions table
#' @param ... Ignored.
#' @param .n A single integer of the number of versions to get.
#' This function calls the GitHub API this times.
#' @return A [tibble::tibble] of RStudio IDE versions.
#' - rstudio_version: Character, RStudio version. e.g. `"2023.12.0+369"`.
#' - rstudio_commit_date: Date, the date of the release commit.
rstudio_versions <- function(..., .n = 10) {
  gert::git_remote_ls(remote = "https://github.com/rstudio/rstudio.git") |>
    dplyr::filter(stringr::str_detect(ref, "^refs/tags/v")) |>
    dplyr::mutate(
      rstudio_version = stringr::str_extract(ref, r"(\d+\.\d+\.\d+.{0,1}\d*)"),
      commit_url = glue::glue("https://api.github.com/repos/rstudio/rstudio/commits/{oid}"),
      .keep = "none"
    ) |>
    dplyr::slice_tail(n = .n) |>
    dplyr::rowwise() |>
    dplyr::mutate(rstudio_commit_date = get_github_commit_date(commit_url)) |>
    dplyr::ungroup() |>
    tidyr::drop_na() |>
    dplyr::select(
      rstudio_version,
      rstudio_commit_date
    ) |>
    dplyr::arrange(rstudio_commit_date)
}


#' Get the commit date from a GitHub API URL for a Git commit
#' @param commit_url A single character of GitHub API URL for a commit.
#' e.g. `"https://api.github.com/repos/rstudio/rstudio/commits/7d165dcfc1b6d300eb247738db2c7076234f6ef0"`
#' @return A character of commit date.
#' @examples
#' get_github_commit_date("https://api.github.com/repos/rstudio/rstudio/commits/7d165dcfc1b6d300eb247738db2c7076234f6ef0")
get_github_commit_date <- function(commit_url) {
  res <- httr2::request(commit_url) |>
    httr2::req_headers(Accept = "application/vnd.github.v3+json") |>
    httr2::req_perform()

  commit_date <- res |>
    httr2::resp_body_json() |>
    purrr::pluck("commit", "committer", "date", .default = NA) |>
    lubridate::as_date()

  commit_date
}


#' Get the latest version from Git remote tags
#' @param remote_repo A single character of Git remote repository URL.
#' @return A character of the latest version.
#' @examples
#' latest_version_of_git_repo("https://github.com/OSGeo/PROJ.git")
latest_version_of_git_repo <- function(remote_repo) {
  gert::git_remote_ls(remote = remote_repo) |>
    dplyr::pull(ref) |>
    stringr::str_subset(r"(^refs/tags/v?(\d+\.){2}\d+$)") |>
    stringr::str_extract(r"((\d+\.)*\d+$)") |>
    package_version() |>
    sort() |>
    utils::tail(1) |>
    as.character()
}


r_versions_with_freeze_dates() |>
  readr::write_tsv("build/variables/r-versions.tsv", na = "")


ubuntu_lts_versions() |>
  readr::write_tsv("build/variables/ubuntu-lts-versions.tsv", na = "")


rstudio_versions() |>
  readr::write_tsv("build/variables/rstudio-versions.tsv", na = "")


# geospatial-dev-osgeo's variables
tibble::tibble(
  proj_version = latest_version_of_git_repo("https://github.com/OSGeo/PROJ.git")
) |>
  readr::write_tsv("build/variables/proj-versions.tsv", na = "")


tibble::tibble(
  gdal_version = latest_version_of_git_repo("https://github.com/OSGeo/gdal.git")
) |>
  readr::write_tsv("build/variables/gdal-versions.tsv", na = "")


tibble::tibble(
  geos_version = latest_version_of_git_repo("https://github.com/libgeos/geos.git")
) |>
  readr::write_tsv("build/variables/geos-versions.tsv", na = "")
