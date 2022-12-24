#!/usr/bin/env Rscript

library(jsonlite)
library(dplyr, warn.conflicts = FALSE)
library(tibble)
library(purrr, warn.conflicts = FALSE)
library(stringr)
library(rlang, warn.conflicts = FALSE)


.image_full_name <- function(image_name) {
  full_name <- dplyr::case_when(
    stringr::str_detect(image_name, r"(^.+\..+/.+/.+)") ~ image_name,
    stringr::str_count(image_name, "/") == 0 ~ stringr::str_c("docker.io/library/", image_name),
    stringr::str_count(image_name, "/") == 1 ~ stringr::str_c("docker.io/", image_name)
  )

  if (!stringr::str_detect(image_name, ":")) full_name <- stringr::str_c(full_name, ":latest")

  return(full_name)
}


.version_or_zap <- function(tag) {
  if (stringr::str_detect(tag, r"(^\d+\.\d+\.\d+$)")) {
    stringr::str_c("R-", tag)
  } else {
    rlang::zap()
  }
}


.bake_list <- function(stack_file_path) {
  stack_content <- jsonlite::read_json(stack_file_path)

  stack_tag <- stack_content$TAG

  df_content <- stack_content$stack |>
    tibble::enframe() |>
    dplyr::transmute(
      name = purrr::map_chr(value, "IMAGE", .default = NA),
      context = "./",
      dockerfile = stringr::str_c("dockerfiles/", name, "_", stack_tag, ".Dockerfile"),
      labels = purrr::map(value, "labels"),
      tags = purrr::map(
        value,
        ~ if (!is.null(.x$tags)) .x$tags else list(stringr::str_c("docker.io/rocker/", .x$IMAGE, ":", stack_tag))
      ),
      platforms = purrr::map(value, "platforms", .default = list("linux/amd64")),
      `cache-from` = purrr::map(value, "cache-from", .default = NULL),
      `cache-to` = purrr::map(value, "cache-to", .default = list("type=inline")),
      base_image = purrr::map_chr(value, "FROM")
    ) |>
    dplyr::rowwise() |>
    dplyr::mutate(
      labels = list(purrr::list_modify(
        labels,
        org.opencontainers.image.base.name = .image_full_name(base_image),
        org.opencontainers.image.version = .version_or_zap(stack_tag)
      )),
      `cache-from` = list(if (is.null(`cache-from`)) tags[1] else `cache-from`)
    ) |>
    dplyr::ungroup() |>
    dplyr::select(
      name,
      context,
      dockerfile,
      labels,
      tags,
      platforms,
      `cache-from`,
      `cache-to`
    )

  list_content <- list(
    group = if (!is.null(stack_content$group)) {
      stack_content$group
    } else {
      list(c(list(
        default = list(c(list(
          targets = if (length(df_content$name) == 1) list(df_content$name) else c(df_content$name)
        )))
      )))
    },
    target = purrr::transpose(dplyr::select(df_content, !name), .names = df_content$name)
  )

  return(list_content)
}


write_bakejson <- function(stack_file_path) {
  output_path <- stack_file_path |>
    stringr::str_replace("^stacks/", "bakefiles/") |>
    stringr::str_replace(".json$", ".docker-bake.json")

  .bake_list(stack_file_path) |>
    jsonlite::write_json(output_path, pretty = TRUE, auto_unbox = TRUE)

  message(output_path)
}


message("\nstart writing docker-bake.json files.")

list.files(path = "stacks", pattern = "\\.json$", full.names = TRUE) |>
  purrr::walk(write_bakejson)

message("make-bakejson.R done!\n")
