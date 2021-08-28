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
  dplyr::summarise(
    r_version = stringr::str_extract(value, "\\d+\\.\\d+\\.\\d+"),
    group = unlist(purrr::map(value, .get_group_names)),
    r_major_minor_version = readr::parse_number(r_version),
    r_patch_version = as.integer(stringr::str_extract(r_version, "\\d+$")),
    .groups = "drop"
  ) |>
  dplyr::arrange(r_major_minor_version, r_patch_version) |>
  dplyr::select(!tidyselect::matches("r_.+_version"))


message("\nstart writing matrix files.")

df_args |>
  .write_matrix("build/matrix/all.json")

df_args |>
  dplyr::filter(r_version == dplyr::last(r_version)) |>
  .write_matrix("build/matrix/latest.json")

message("make-matrix.R done!\n")
