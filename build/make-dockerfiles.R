#!/usr/bin/env Rscript

inherit_global <- function(image, global){
  c(image, global[! names(global) %in% names(image) ])
}

paste_if <- function(element, image){

  key <- sub("_.*", "", element)
  value <- unlist(image[[element]])

  if(is.null(value))
    return(NA)

  if(!is.null(names(value)))
    out <- paste0(key, " ", names(value), "=", value, collapse = "\n")
  else
    out <- paste0(key, " ", value, collapse = "\n")

  paste0(out, "\n")
}

# image <- stack$stack[[1]]

write_dockerfiles <- function(stack, global){
  lapply(stack, function(image){

    image <- inherit_global(image, global)

    body <- paste(na.omit(c(
      paste_if("FROM", image),
      paste_if("LABEL", image),
      paste_if("ENV", image),
      paste_if("COPY_a_script", image),
      paste_if("RUN_a_script", image),
      paste_if("ENV_after_a_script", image),
      paste_if("COPY", image),
      paste_if("RUN", image),
      paste_if("EXPOSE", image),
      paste_if("CMD", image),
      paste_if("USER", image),
      paste_if("WORKDIR", image)
    )), collapse = "\n")

    path <- file.path("dockerfiles", paste0(image$IMAGE, "_", image$TAG, ".Dockerfile"))
    writeLines(body, path, sep = "")

    message(paste(path))
  })
}

stack_files <- list.files("stacks", pattern = "\\.json$",full.names = TRUE)
stacks <- lapply(stack_files, jsonlite::read_json)

devnull <- lapply(stacks, function(stack){
  global <- stack[ !(names(stack) %in% c("ordered", "stack"))]
  write_dockerfiles(stack$stack, global)
})

message(paste("make-dockerfiles.R done!\n"))
