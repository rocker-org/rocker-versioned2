library(yaml)
library(jsonlite)
library(purrr)


write_compose <- 
  function(json_file, out = "docker-compose.yml", org = "rocker"){
  
  json <- jsonlite::read_json(json_file)
  prefix <- "dockerfiles/Dockerfile_"
  name <- purrr::map_chr(json, "ROCKER_IMAGE")
  tag <-  purrr::map_chr(json, "ROCKER_TAG")
  dockerfiles <- paste0(prefix, name, "_", tag)
  names(dockerfiles) <- name
  
  image_name <- function(d, org){
    x <- gsub(prefix, "", d)
    x <- gsub("_", ":", x)
    paste(org, x, sep="/")
  }
  
  
  services <- lapply(dockerfiles, function(d) 
    list(image = image_name(d, org),
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
  yaml::write_yaml(compose, out)

}



write_compose("versions-cuda.json", "docker-compose.yml", org = "rocker")
write_compose("versions-cuda.json", "docker-compose-gh.yml", 
              org = "docker.pkg.github.com/noamross/rocker-versioned2")






