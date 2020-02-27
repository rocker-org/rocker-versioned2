library(yaml)
library(jsonlite)
library(purrr)

json <- read_json("versions-cuda.json")

prefix <- "dockerfiles/Dockerfile_"
name <- map_chr(json, "ROCKER_IMAGE")
tag <-  map_chr(json, "ROCKER_TAG")
dockerfiles <- paste0(prefix, name, "_", tag)
names(dockerfiles) <- name

image_name <- function(d){
  x <- gsub(prefix, "", d)
  x <- gsub("_", ":", x)
  paste0("rocker/", x)
}

services <- lapply(dockerfiles, function(d) 
  list(image = image_name(d),
       build = list(
         context = ".",
         dockerfile = d
         )
       )
)

compose <- list(
  version = "3",
  services =  services
)

write_yaml(compose, "docker-compose.yml")


