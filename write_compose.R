#!/usr/bin/env Rscript

library(yaml)


write_compose <- 
  function(json_file, out = "docker-compose.yml", org = "rocker"){
    
    json <- yaml::read_yaml(json_file) #jsonlite::read_json(json_file)
    prefix <- "dockerfiles/Dockerfile_"
    map_chr <- function(x, name) vapply(x, `[[`, character(1L), name)
    
    name <- map_chr(json, "ROCKER_IMAGE")
    tag <-  map_chr(json, "ROCKER_TAG")
    
    dockerfiles <- paste0(prefix, name, "_", tag)
    names(dockerfiles) <- name
    
    image_name <- function(d, org){
      x <- gsub(prefix, "", d)
      x <- gsub("_", ":", x)
      paste(org, x, sep="/")
    }
    
    # FIXME use FROM image, don't assume these are listed in build order!
    depends_on <- c("", name[1:(length(name)-1)])
    
    
    not_blank <- function(x) if(x == "") return(NULL) else x
    is_empty <- function(x) length(x) == 0 || is.null(x)
    compact <- function (l) Filter(Negate(is_empty), l)
    
    services <- vector("list", length(dockerfiles))
    names(services) <- name
    for(i in seq_along(dockerfiles)){
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
    
  }


## FIXME generate these programmatically from `stacks/`
write_compose("stacks/core-3.6.3-gpu.json", "compose/core-3.6.3-gpu.yml", org = "rocker")
write_compose("stacks/extensions-3.6.3-gpu.json", "compose/extensions-3.6.3-gpu.yml", org = "rocker")
write_compose("stacks/core-3.6.3.json", "compose/core-3.6.3.yml",   org = "rocker")
write_compose("stacks/extensions-3.6.3.json", "compose/extensions-3.6.3.yml", org = "rocker")



## rockerdev org is just for testing!
write_compose("stacks/core-3.6.3-gpu.json", "compose-rockerdev/core-3.6.3-gpu.yml",   org = "rockerdev")
write_compose("stacks/extensions-3.6.3-gpu.json", "compose-rockerdev/extensions-3.6.3-gpu.yml", org = "rockerdev")
write_compose("stacks/core-3.6.3.json", "compose-rockerdev/core-3.6.3.yml",   org = "rockerdev")
write_compose("stacks/extensions-3.6.3.json", "compose-rockerdev/extensions-3.6.3.yml", org = "rockerdev")

write_compose("stacks/shiny-3.6.3.json", "compose-rockerdev/shiny-3.6.3.yml", org = "rockerdev")







