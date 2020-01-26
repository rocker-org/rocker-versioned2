#!/usr/bin/env Rscript

library(stevedore)
library(igraph)

dc <- docker_client()
images_list <- jsonlite::read_json("versions.json")
tags <- 
  vapply(images_list, 
         function(.) paste0("rocker/", .$ROCKER_IMAGE, ":", .$ROCKER_TAG),
         character(1))
names(images_list) <- tags
names(tags) <- tags

from <- vapply(images_list, function(.) .$FROM_IMAGE, character(1))
image_graph <- igraph::graph_from_data_frame(cbind(from, tags))
tag_order <- grep("^rocker", names(igraph::topo_sort(image_graph)), value = TRUE)


images_list <- images_list[tag_order]
tags <- tags[tag_order]

dockerfiles <- 
  file.path(
    "dockerfiles",
    vapply(images_list,
           function(.) paste0("Dockerfile_", .$ROCKER_IMAGE, "_", .$ROCKER_TAG),
           character(1))
  )

build_fn <- function(dockerfile, tag) {
  message("Building ", tag, "...")
  dc$image$build(dockerfile = dockerfile, tag = tag, context = ".")
}

mapply(build_fn, dockerfile = dockerfiles, tag = tags)
