#!/usr/bin/env Rscript

library(whisker)

versions_grid <- read.csv("versions-grid.csv", stringsAsFactors = FALSE)

images_list <- split(
  versions_grid, 
  paste(versions_grid$ROCKER_IMAGE, versions_grid$ROCKER_TAG, sep = "_"))

x <- lapply(images_list, function(z) {
  
  z <- Filter(Negate(function(.) {is.na(.) | is.null(.) | . == ""}), z)
  
  template <- paste(
    c(readLines("partials/Dockerfile.base.partial"), "",
      readLines(paste0("partials/Dockerfile.", z$ROCKER_IMAGE, ".partial"))),
    collapse = "\n"
  )
  dockerfile_text <- whisker::whisker.render(template, data = z)
  dfile = paste0("dockerfiles/Dockerfile_", z$ROCKER_IMAGE, "_", z$ROCKER_TAG)
  cat(
    dockerfile_text, 
    file = dfile)
  cat(dfile, "\n")
  return(dockerfile_text)
})
