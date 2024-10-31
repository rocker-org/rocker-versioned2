#' Search the latest P3M CRAN mirror URL for Linux at a given date
#' @param date A single character of date like `"2023-10-30"` or `NA`.
#' If `NA`, the "latest" URL will be returned.
#' @param distro_version_name A character of distro version name like `"focal"`.
#' @param r_version A character of R version like `"4.3.0"`.
#' @return A character of P3M CRAN mirror URL.
#' @examples
#' latest_p3m_cran_url_linux("2023-10-30", "focal", "4.3.0")
#' latest_p3m_cran_url_linux(NA, "focal", "4.3.0")
latest_p3m_cran_url_linux <- function(date, distro_version_name, r_version) {
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
    purrr::pmap_chr(make_p3m_cran_url_linux) |>
    unique()

  for (i in seq_along(urls_try)) {
    .url <- urls_try[i]
    if (is_cran_url_available(.url, r_version)) break
    .url <- NA_character_
  }

  if (is.na(.url)) rlang::abort("\nCRAN mirrors are not available!\n")

  .url
}


#' A funtion to make P3M CRAN mirror URL for Linux
#' @param date A character vector of dates like `"2023-10-30"`.
#' If `NA`, the "latest" URL will be returned.
#' @param distro_version_name A character of distro version name like `"focal"`.
#' @param type A character of package type, `"source"` (default) or `"binary"`.
#' @return A character of P3M CRAN mirror URL.
#' @examples
#' make_p3m_cran_url_linux(c("2023-10-30", NA), "focal", "binary")
make_p3m_cran_url_linux <- function(date, distro_version_name, type = "source") {
  base_url <- "https://p3m.dev/cran"

  dplyr::case_when(
    type == "source" & is.na(date) ~ glue::glue("{base_url}/latest"),
    type == "binary" & is.na(date) ~ glue::glue("{base_url}/__linux__/{distro_version_name}/latest"),
    type == "source" ~ glue::glue("{base_url}/{date}"),
    type == "binary" ~ glue::glue("{base_url}/__linux__/{distro_version_name}/{date}")
  )
}


#' Check if a CRAN URL is available via [pak::repo_ping()]
#' @param url A single character of CRAN URL.
#' @param r_version A character of R version like `"4.3.0"`.
is_cran_url_available <- function(url, r_version) {
  glue::glue("\n\nfor R {r_version}, repo_ping to {url}\n\n") |>
    cat()

  is_available <- pak::repo_ping(cran_mirror = url, r_version = r_version, bioc = FALSE) |>
    dplyr::filter(name == "CRAN") |>
    dplyr::pull(ok)

  is_available
}


#' Check if an RStudio deb package (amd64) is available
#' @param rstudio_version A single character of RStudio version like `"2023.12.0+369"`.
#' @param ubuntu_series A character of Ubuntu series like `"jammy"`.
#' @return A logical value.
#' @examples
#' is_rstudio_deb_available("2023.12.0+369", "jammy")
is_rstudio_deb_available <- function(rstudio_version, ubuntu_series) {
  os_ver <- dplyr::case_match(
    ubuntu_series,
    "focal" ~ "bionic",
    "noble" ~ "jammy",
    .default = ubuntu_series
  )

  glue::glue("\n\nChecking RStudio Sever {rstudio_version} deb package for {os_ver}\n\n") |>
    cat()

  is_available <- glue::glue(
    "https://download2.rstudio.org/server/{os_ver}/amd64/rstudio-server-{rstudio_version}-amd64.deb"
  ) |>
    stringr::str_replace_all("\\+", "-") |>
    httr2::request() |>
    httr2::req_error(is_error = \(...) FALSE) |>
    httr2::req_perform() |>
    httr2::resp_is_error() |>
    isFALSE()

  is_available
}


#' Get the latest CTAN URL for a given date
#' @param date A [Date] class vector.
#' If `NA`, the "latest" URL will be returned.
#' @return A character of CTAN URL.
#' @examples
#' latest_ctan_url(as.Date(c("2023-10-30", NA)))
latest_ctan_url <- function(date) {
  .url <- dplyr::if_else(
    is.na(date), "https://mirror.ctan.org/systems/texlive/tlnet",
    stringr::str_c("https://www.texlive.info/tlnet-archive/", format(date, "%Y/%m/%d"), "/tlnet")
  )

  .url
}


#' Paste each element of vectors in a cartesian product
#' @param ... Dynamic dots. Character vectors to paste.
#' @return A character vector.
#' @examples
#' outer_paste(c("a", "b"), "-", c("c", "d", "e"))
outer_paste <- function(...) {
  .paste <- function(x, y) {
    outer(x, y, stringr::str_c) |>
      c()
  }

  out <- rlang::list2(...) |>
    purrr::reduce(.paste)

  out
}


rocker_versioned_args <- function(
    ...,
    r_versions_file = "build/variables/r-versions.tsv",
    ubuntu_lts_versions_file = "build/variables/ubuntu-lts-versions.tsv",
    rstudio_versions_file = "build/variables/rstudio-versions.tsv",
    n_r_versions = 6) {
  df_all <- readr::read_tsv(r_versions_file, show_col_types = FALSE) |>
    dplyr::arrange(as.numeric_version(r_version)) |>
    dplyr::mutate(
      r_minor_version = stringr::str_extract(r_version, r"(^\d+\.\d+)") |>
        as.numeric_version(),
      r_major_version = stringr::str_extract(r_version, r"(^\d+)") |>
        as.numeric_version(),
    ) |>
    dplyr::mutate(
      r_minor_latest = dplyr::if_else(dplyr::row_number() == dplyr::n(), TRUE, FALSE),
      .by = r_minor_version
    ) |>
    dplyr::mutate(
      r_major_latest = dplyr::if_else(dplyr::row_number() == dplyr::n(), TRUE, FALSE),
      .by = r_major_version
    ) |>
    dplyr::select(!c(r_minor_version, r_major_version)) |>
    dplyr::slice_tail(n = n_r_versions) |>
    tidyr::expand_grid(
      readr::read_tsv(
        ubuntu_lts_versions_file,
        show_col_types = FALSE,
        col_types = list(ubuntu_version = readr::col_character())
      )
    ) |>
    dplyr::filter(r_release_date >= ubuntu_release_date + 90) |>
    dplyr::slice_max(ubuntu_release_date, with_ties = FALSE, by = r_version) |>
    tidyr::expand_grid(
      readr::read_tsv(
        rstudio_versions_file,
        show_col_types = FALSE
      )
    ) |>
    dplyr::filter(
      r_freeze_date > rstudio_commit_date | is.na(r_freeze_date)
    )

  df_available_rstudio <- df_all |>
    dplyr::distinct(ubuntu_series, rstudio_version) |>
    dplyr::filter(
      purrr::map2_lgl(rstudio_version, ubuntu_series, is_rstudio_deb_available)
    )

  df_all |>
    dplyr::semi_join(df_available_rstudio, by = c("ubuntu_series", "rstudio_version")) |>
    dplyr::slice_max(rstudio_version, with_ties = FALSE, by = c(r_version, ubuntu_series)) |>
    dplyr::mutate(
      ctan = latest_ctan_url(r_freeze_date),
      cran = purrr::pmap_chr(
        list(r_freeze_date, ubuntu_series, r_version),
        \(...) latest_p3m_cran_url_linux(...)
      )
    ) |>
    dplyr::select(
      r_version,
      r_release_date,
      r_freeze_date,
      ubuntu_series,
      ubuntu_version,
      cran,
      rstudio_version,
      ctan,
      r_major_latest,
      r_minor_latest
    )
}


# Add devel version
df_args <- rocker_versioned_args() |> (\(x)
dplyr::add_row(
  x,
  r_version = "devel",
  ubuntu_series = "latest",
  cran = "https://cloud.r-project.org",
  rstudio_version = x$rstudio_version |>
    utils::tail(1),
  ctan = x$ctan |>
    utils::tail(1)
))()


df_args |>
  purrr::pwalk(
    \(...) {
      dots <- rlang::list2(...)
      dots |>
        jsonlite::write_json(
          glue::glue("build/args/{dots$r_version}.json"),
          auto_unbox = TRUE,
          pretty = TRUE
        )
    }
  )


# Update history.tsv
df_history <- readr::read_tsv(
  "build/args/history.tsv",
  col_types = list(ubuntu_version = readr::col_character()),
  show_col_types = FALSE
)

df_args |>
  dplyr::filter(!r_version == "devel") |>
  dplyr::select(names(df_history)) |>
  dplyr::union(df_history) |>
  dplyr::distinct(r_version, .keep_all = TRUE) |>
  dplyr::arrange(r_version) |>
  readr::write_tsv("build/args/history.tsv", na = "")
