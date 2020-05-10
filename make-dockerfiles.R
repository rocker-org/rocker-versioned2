#!/usr/bin/env Rscript

buildkit_cache = isTRUE(Sys.getenv("BUILDKIT_CACHE") == "1")
cache_line = "--mount=type=cache,id=rocker_ccache,target=/.rocker_ccache --mount=type=cache,id=rocker_cache_apt,target=/var/cache/apt --mount=type=cache,id=rocker_lib_apt,target=/var/lib/apt"
syntax_line = "# syntax = docker/dockerfile:1.0-experimental"
cache_arg = c("BUILDKIT_CACHE"="1",
              "R_MAKEVARS_SITE"="/rocker_scripts/Makevars.ccache",
              "CCACHE_DIR"="/.rocker_ccache",
              "APT_CONFIG"="/rocker_scripts/apt-config")

inherit_global <- function(image, global){
  c(image, global[! names(global) %in% names(image) ])
}

paste_if <- function(element, image){

  key <- element
  if (key == "RUN" && buildkit_cache) key = paste(key, cache_line)
  value <- unlist(image[[element]])

  if(is.null(value))
    return("")

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
    if (buildkit_cache) image[["ARG"]] <- c(cache_arg, image[["ARG"]])

    body <- paste(c(
      paste_if("FROM", image),
      paste_if("LABEL", image),
      paste_if("ARG", image),
      paste_if("ENV", image),
      paste_if("COPY", image),
      paste_if("RUN", image),
      paste_if("EXPOSE", image),
      paste_if("CMD", image),
      paste_if("USER", image),
      paste_if("WORKDIR", image)),
      collapse ="\n"
    )
    if (buildkit_cache) body <- c(syntax_line, body)

    path <- file.path("dockerfiles", paste("Dockerfile", image$IMAGE, image$TAG, sep="_"))
    writeLines(body, path)

    message(paste(path))
  })
}



stack_files <- list.files("stacks", full.names = TRUE)
stacks <- lapply(stack_files, jsonlite::read_json)

devnull <- lapply(stacks, function(stack){
  global <- stack[ !(names(stack) %in% c("ordered", "stack"))]
  write_dockerfiles(stack$stack, global)
})


message(paste("make-dockerfiles.R done!\n"))






