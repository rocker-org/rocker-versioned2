#!/usr/bin/env Rscript

library(yaml)


inherit_global <- function(image, global){
  c(image, global[! names(global) %in% names(image) ])
}


#' @param ordered should the images be built in the order listed?  
#' We cannot necesarily build the FROM image first since our stack need
#' not define the build rule for the FROM image. (Obviously that's true
#' for the first image, but can be true for later images too).
#' @param latest should tag "latest" be added to the image? 
write_compose <- 
  function(json_file, out = "docker-compose.yml", org = "rocker"){
    
    
    json <- yaml::read_yaml(json_file) #jsonlite::read_json(json_file)
    global <- json[ !(names(json) %in% c("ordered", "stack"))]
    json_stack <- lapply(json$stack, inherit_global, global)
    
    ordered <- isTRUE(json$ordered)
    
    prefix <- "dockerfiles/Dockerfile_"
    map_chr <- function(x, name) vapply(x, `[[`, character(1L), name)
    map_lgl <- function(x, FUN) vapply(x, FUN, logical(1L))
    
    name <- map_chr(json_stack, "IMAGE")
    tag <-  map_chr(json_stack, "TAG")
    latest <- map_lgl(json_stack, function(z) isTRUE(z[["latest"]]))
    
    dockerfiles <- paste0(prefix, name, "_", tag)
    names(dockerfiles) <- name
    
    image_name <- function(d, org, latest=FALSE){
      x <- gsub(prefix, "", d)
      x <- gsub("_", ":", x)
      if (latest) x <- gsub(":.*$", ":latest", x)
      paste(org, x, sep = "/")
    }
    service_name <- function(d, latest=FALSE){
      x <- gsub(prefix, "", d)
      if (latest) x <- gsub("_[^_]*$", "-latest", x)
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
      if (latest[i]) {
        latest_entry <- list(compact(list(
          image = image_name(d, org, latest = TRUE),
          depends_on = compact(list(not_blank(depends_on[i]))),
          build = list(
            context = "..",
            dockerfile = d
          )
        )))
        names(latest_entry) <- service_name(d, latest = TRUE)
        services <- c(services, latest_entry)
      }
    }
    
    
    compose <- list(
      version = "3",
      services =  services
    )
    yaml::write_yaml(compose, out)
    
    message(paste(out))  
  }


############ rockerdev org is just for testing! ###########
stacks <- list.files("stacks", full.names=TRUE)
compose <- file.path("compose", gsub(".json$", ".yml", basename(stacks)))
devfiles <- data.frame(stacks, compose, org = "rockerdev")                
devnull <- apply(devfiles, 1, function(f) write_compose(f[1], f[2], org = f[3]))              

message(paste("write-compose.R done!\n"))




