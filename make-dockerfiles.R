#!/usr/bin/env Rscript

library(whisker)

#versions_grid <- read.csv("versions-grid.csv", stringsAsFactors = FALSE)

images_list <- jsonlite::read_json("versions.json")

#images_list <- split(
#  versions_grid, 
#  paste(versions_grid$ROCKER_IMAGE, versions_grid$ROCKER_TAG, sep = "_")
#)

x <- lapply(images_list, function(z) {
  
  ## drop empty env / version fields, aka compact
#  z <- Filter(Negate(function(.) {is.na(.) | is.null(.) | . == ""}), z)
  
  partials <- paste0(
    "partials/Dockerfile.",
    c("start", strsplit(z$PARTIAL_DOCKERFILES, "\\s*;\\s*")[[1]], "end"),
    ".partial"
    )
  template <- paste(unlist(lapply(partials, readLines)), collapse = "\n")

  dockerfile_text <- whisker::whisker.render(template, data = z)
  dfile = paste0("dockerfiles/Dockerfile_", z$ROCKER_IMAGE, "_", z$ROCKER_TAG)
  cat(
    dockerfile_text, 
    file = dfile)
  cat(dfile, "\n")
  return(dockerfile_text)
})
