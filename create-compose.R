library(yaml)
library(jsonlite)
library(purrr)

json <- read_json("versions-cuda.json")

name <- map_chr(json, "ROCKER_IMAGE")
tag <-  map_chr(json, "ROCKER_TAG")
dockerfiles <- paste0("dockerfiles/Dockerfile_", name, "_", tag)
names(dockerfiles) <- name
services <- lapply(dockerfiles, function(d) 
  list(context = ".",
       build = list(dockerfile = d)))

compose <- list(
  version = "3",
  services =  services
)

write_yaml(compose, "docker-compose.yml")


