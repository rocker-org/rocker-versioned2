#!/usr/bin/env Rscript

library(stevedore)
dc <- docker_client()

dockerfiles <- list.files("dockerfiles", full.names = TRUE)
tags <- gsub("(dockerfiles/Dockerfile_)(.*)_(.*)$", "rocker/\\2:\\3", dockerfiles, perl = TRUE)

build_fn <- function(dockerfile, tag) {
  dc$image$build(dockerfile = dockerfile, tag = tag, context = ".")
}

mapply(build_fn, dockerfile = dockerfiles, tag = tags)
