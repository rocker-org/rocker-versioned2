#!/usr/bin/env Rscript

library(yaml)


inherit_global <- function(image, global){
  c(image, global[! names(global) %in% names(image) ])
}

#' @param ordered should the images be built in the order listed?
#' We cannot necesarily build the FROM image first since our stack need
#' not define the build rule for the FROM image. (Obviously that's true
#' for the first image, but can be true for later images too).
write_compose <-
  function(json_file, out = "docker-compose.yml", org = "rocker", json = NULL){


    if(is.null(json)) json <- yaml::read_yaml(json_file) #jsonlite::read_json(json_file)
    global <- json[ !(names(json) %in% c("ordered", "stack"))]
    json_stack <- lapply(json$stack, inherit_global, global)

    ordered <- isTRUE(json$ordered)

    prefix <- "dockerfiles/"
    suffix <- ".Dockerfile"
    map_chr <- function(x, name) vapply(x, `[[`, character(1L), name)
    map_lgl <- function(x, FUN) vapply(x, FUN, logical(1L))

    name <- map_chr(json_stack, "IMAGE")
    tag <-  map_chr(json_stack, "TAG")

    dockerfiles <- paste0(prefix, name, "_", tag, suffix)
    names(dockerfiles) <- name

    image_name <- function(d, org){
      x <- gsub(prefix, "", d)
      x <- gsub(suffix, "", x)
      x <- gsub("_", ":", x)
      paste(org, x, sep = "/")
    }
    service_name <- function(d){
      x <- gsub(prefix, "", d)
      x <- gsub(suffix, "", x)
    }

    image <- paste(name, tag, sep = "-")

    ## we only enforce order if requested
    depends_on <- rep("", length(image))
    if (ordered)
      depends_on <- c("", image[1:(length(image) - 1)])


    not_blank <- function(x) if (x == "") return(NULL) else x
    is_empty <- function(x) length(x) == 0 || is.null(x)
    compact <- function(l) Filter(Negate(is_empty), l)

    services <- vector("list", length(dockerfiles))
    names(services) <- image
    for (i in seq_along(dockerfiles)) {
      d <- dockerfiles[[i]]
      services[[i]] <- compact(list(
        image = image_name(d, org),
        depends_on = compact(list(not_blank(depends_on[i]))),
        build = list(
          context = "..",
          dockerfile = d
        )
      ))
    }


    compose <- list(
      version = "3",
      services =  services
    )
    yaml::write_yaml(compose, out)

    message(paste(out))
  }

############ rockerdev org is just for testing! ###########
stacks <- list.files("stacks", pattern = "\\.json$",full.names=TRUE)
compose <- file.path("compose", gsub(".json$", ".yml", basename(stacks)))
devfiles <- data.frame(stacks, compose, org = "rocker")
devnull <- apply(devfiles, 1, function(f) write_compose(f[1], f[2], org = f[3]))


## write `core-devel.yml` for daily build of devel images.
stack_devel <- "stacks/devel.json"
develcontent <- yaml::read_yaml(stack_devel)
### Only use r-ver, rstudio, tidyverse, verse
develcontent$stack <- develcontent$stack[1:4]
write_compose(stack_devel, "compose/core-devel.yml", json = develcontent)

message(paste("write-compose.R done!\n"))
