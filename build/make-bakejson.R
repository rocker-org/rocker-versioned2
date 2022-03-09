#!/usr/bin/env Rscript

library(jsonlite)
library(dplyr, warn.conflicts = FALSE)
library(tibble)
library(purrr, warn.conflicts = FALSE)
library(stringr)


.image_full_name <- function(image_name) {
  full_name <- dplyr::case_when(
    stringr::str_detect(image_name, "^.+\\..+/.+/.+") ~ image_name,
    stringr::str_count(image_name, "/") == 0 ~ stringr::str_c("docker.io/library/", image_name),
    stringr::str_count(image_name, "/") == 1 ~ stringr::str_c("docker.io/", image_name)
  )

  if (!stringr::str_detect(image_name, ":")) full_name <- stringr::str_c(full_name, ":latest")

  return(full_name)
}


.version_or_null <- function(tag) {
  if (stringr::str_detect(tag, "^\\d+\\.\\d+\\.\\d+$")) {
    return(stringr::str_c("R-", tag))
  } else {
    return(NULL)
  }
}


.bake_list <- function(stack_file) {
  stack_content <- jsonlite::read_json(stack_file)

  stack_tag <- stack_content$TAG

  content_list <- stack_content$stack %>%
    tibble::enframe() %>%
    dplyr::transmute(
      name = purrr::map_chr(value, "IMAGE", .default = NA),
      context = "./",
      dockerfile = paste0("dockerfiles/", name, "_", stack_tag, ".Dockerfile"),
      labels = purrr::map(value, "labels"),
      tags = purrr::map(
        value,
        ~ if (!is.null(.x$tags)) .x$tags else list(paste0("docker.io/rocker/", .x$IMAGE, ":", stack_tag))
      ),
      platforms = purrr::map(value, "platforms", .default = list("linux/amd64")),
      `cache-from` = purrr::map(value, "cache-from", .default = list("")),
      `cache-to` = purrr::map(value, "cache-to", .default = list("")),
      base_image = map_chr(value, "FROM")
    ) %>%
    dplyr::rowwise() %>%
    dplyr::mutate(
      labels = list(purrr::list_modify(
        labels,
        org.opencontainers.image.base.name = .image_full_name(base_image),
        org.opencontainers.image.version = .version_or_null(stack_tag)
      ))
    ) %>%
    dplyr::ungroup() %>%
    dplyr::select(
      name,
      context,
      dockerfile,
      labels,
      tags,
      platforms,
      `cache-from`,
      `cache-to`
    ) %>%
    {
      list(
        group = if (!is.null(stack_content$group)) {
          stack_content$group
        } else {
          list(c(list(default = list(c(list(targets = if (length(.$name) == 1) list(.$name) else c(.$name)))))))
        },
        target = purrr::transpose(dplyr::select(., !name), .names = .$name)
      )
    }

  return(content_list)
}


write_bakejson <- function(stack_file) {
  output_path <- sub("^stacks/", "bakefiles/", stack_file) %>% {
    sub(".json$", ".docker-bake.json", .)
  }

  .bake_list(stack_file) %>%
    jsonlite::write_json(output_path, pretty = TRUE, auto_unbox = TRUE)

  message(output_path)
}


message("\nstart writing docker-bake.json files.")

list.files(path = "stacks", pattern = "\\.json$", full.names = TRUE) %>%
  purrr::walk(write_bakejson)

message("make-bakejson.R done!\n")
