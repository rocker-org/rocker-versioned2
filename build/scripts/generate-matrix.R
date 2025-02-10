#' @param r_versions A character vector of R versions to include in the matrix
#' @param file The file path to write the matrix to
#' @examples
#' write_matrix(c("4.0.0", "4.0.1"), "build/matrix/all.json")
write_matrix <- function(r_versions, file) {
  list(
    r_version = as.list(r_versions),
    group = list("default")
  ) |>
    jsonlite::write_json(file, pretty = TRUE, auto_unbox = TRUE)
}

supported_versions <- fs::dir_ls(path = "build/args", regexp = r"((\d+\.){3}json)") |>
  stringr::str_extract(r"((\d+\.){2}\d)") |>
  R_system_version() |>
  sort() |>
  tibble::tibble(r_version = _) |>
  dplyr::mutate(
    major = r_version$major,
    minor = r_version$minor,
    patch = r_version$patch
  ) |>
  dplyr::slice_tail(n = 2, by = c(major, minor)) |>
  dplyr::filter(
    minor == dplyr::last(minor) | dplyr::lead(minor) == dplyr::last(minor) & patch >= dplyr::lead(patch)
  ) |>
  dplyr::pull(r_version) |>
  as.character()


supported_versions |>
  write_matrix("build/matrix/all.json")


supported_versions |>
  utils::tail(1) |>
  write_matrix("build/matrix/latest.json")


# binder
supported_versions |>
  utils::tail(2) |>
  write_matrix("build/matrix/latest-two.json")
