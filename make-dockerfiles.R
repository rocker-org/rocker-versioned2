#!/usr/bin/env Rscript

library(whisker)

read_stack <- function(x){
  json <- jsonlite::read_json(x)
  json$stack
}
stacks <- list.files("stacks", full.names = TRUE)
images_list <- do.call(c, lapply(stacks, read_stack))

#images_list <- c(
#  jsonlite::read_json("stacks/core-3.6.3.json"),
#  jsonlite::read_json("stacks/core-3.6.3-gpu.json")
#)


ROCKER_DEV_WORKFLOW = Sys.getenv("ROCKER_DEV_WORKFLOW", "0")
x <- lapply(images_list, function(z) {
  
  if (ROCKER_DEV_WORKFLOW == "1") z$ROCKER_DEV_WORKFLOW <- 1
  
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
