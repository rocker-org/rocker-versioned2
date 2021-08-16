#!/usr/bin/env Rscript

library(jsonlite)
library(dplyr, warn.conflicts = FALSE)
library(tibble)
library(purrr, warn.conflicts = FALSE)


write_bakejson <- function(stack_file) {
  output_path <- sub("^stacks/", "bakefiles/", stack_file) %>% {
    sub(".json$", ".docker-bake.json", .)
  }

  stack_content <- jsonlite::read_json(stack_file)

  stack_tag <- stack_content$TAG

  stack_content$stack %>%
    tibble::enframe() %>%
    dplyr::transmute(
      name = purrr::map_chr(value, "IMAGE", .default = NA),
      context = "./",
      dockerfile = paste0("dockerfiles/", name, "_", stack_tag, ".Dockerfile"),
      tags = purrr::map(
        value,
        ~ if (!is.null(.x$tags)) .x$tags else list(paste0("docker.io/rocker/", .x$IMAGE, ":", stack_tag))
      ),
      platforms = purrr::map(value, "platforms", .default = list("linux/amd64"))
    ) %>%
    {
      list(target = purrr::transpose(dplyr::select(., !name), .names = .$name))
    } %>%
    jsonlite::write_json(output_path, pretty = TRUE, auto_unbox = TRUE)

  message(output_path)
}


message("\nstart writing docker-bake.json files.")

list.files(path = "stacks", pattern = "\\.json$", full.names = TRUE) %>%
  purrr::walk(write_bakejson)

message("make-bakejson.R done!\n")
