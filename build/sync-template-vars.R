#!/usr/bin/env Rscript

library(jsonlite)

template_core <- jsonlite::read_json("stacks/core-devel.json")
template_shiny <- jsonlite::read_json("stacks/shiny-devel.json")
template_mlcuda_10 <- jsonlite::read_json("stacks/ml-cuda10.1-devel.json")

# Copy S6_VERSION from core to others.
s6_ver <- template_core$stack[[2]]$ENV$S6_VERSION

template_mlcuda_10$stack[[2]]$ENV$S6_VERSION <- s6_ver
template_shiny$stack[[1]]$ENV$S6_VERSION <- s6_ver


# Rewrite template files.
jsonlite::write_json(template_shiny, "stacks/shiny-devel.json", pretty = TRUE, auto_unbox = TRUE)
jsonlite::write_json(template_mlcuda_10, "stacks/ml-cuda10.1-devel.json", pretty = TRUE, auto_unbox = TRUE)

message("sync-template-vers.R done!\n")