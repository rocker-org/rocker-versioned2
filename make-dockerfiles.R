#!/usr/bin/env Rscript



inherit_global <- function(image, global){
  c(image, global[! names(global) %in% names(image) ])
}

paste_if <- function(element, image){
  
  key <- element
  value <- unlist(image[[element]])
  
  if(is.null(value)) 
    return("")
  
  if(!is.null(names(value)))
     out <- paste0(key, " ", (
       paste0(names(value), "=", value, collapse = " \\ \n    "))
     )
  else
    out <- paste0(key, " ", value, collapse = "\n")
  
  paste0(out, "\n")
}

# image <- stack$stack[[1]]

write_dockerfiles <- function(stack, global){
  lapply(stack, function(image){
    
    image <- inherit_global(image, global)
  
    body <- paste(c(
      paste_if("FROM", image),
      paste_if("LABEL", image),
      paste_if("ENV", image),
      paste_if("COPY", image),
      paste_if("RUN", image),
      paste_if("EXPOSE", image),
      paste_if("CMD", image),
      paste_if("USER", image),
      paste_if("WORKDIR", image)),
      collapse ="\n"
    )
    
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






