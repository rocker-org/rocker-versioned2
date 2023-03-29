#!/usr/bin/env Rscript

library(jsonlite)
library(fs)
library(tibble)
library(stringr)
library(dplyr, warn.conflicts = FALSE)
library(purrr, warn.conflicts = FALSE)
library(readr)
library(tidyselect)

.get_group_names <- function(path) {
  jsonlite::read_json(path)$group[[1]] |>
    names()
}

.write_matrix <- function(data, path) {
  list(
    r_version = unique(data$r_version),
    group = "default",
    include = dplyr::filter(data, group != "default")
  ) |>
    jsonlite::write_json(path, pretty = TRUE, auto_unbox = FALSE)

  message(path)
}

df_args <- fs::dir_ls(path = "bakefiles", regexp = "/\\d+\\.\\d+\\.\\d+\\.docker-bake.json$") |>
  tibble::as_tibble() |>
  dplyr::rowwise() |>
  dplyr::reframe(
    r_version = stringr::str_extract(value, "\\d+\\.\\d+\\.\\d+"),
    group = unlist(purrr::map(value, .get_group_names))
  ) |>
  dplyr::arrange(R_system_version(r_version))

supported_versions <- df_args |>
  dplyr::select(r_version) |>
  dplyr::distinct() |>
  dplyr::mutate(
    sys_ver = R_system_version(r_version),
    major = sys_ver$major,
    minor = sys_ver$minor,
    patch = sys_ver$patch
  ) |>
  dplyr::mutate(
    supported = (patch == dplyr::last(patch)),
    .by = c(major, minor)
  ) |>
  dplyr::mutate(
    major_minor = numeric_version(paste0(major, ".", minor)),
    supported = supported | (major_minor >= nth(unique(major_minor), -2))
  ) |>
  dplyr::filter(supported) |>
  dplyr::pull(r_version)

message("\nstart writing matrix files.")

df_args |>
  dplyr::filter(r_version %in% supported_versions) |>
  .write_matrix("build/matrix/all.json")

df_args |>
  dplyr::filter(r_version == dplyr::last(r_version)) |>
  .write_matrix("build/matrix/latest.json")

message("make-matrix.R done!\n")
