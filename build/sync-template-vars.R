#!/usr/bin/env Rscript

library(jsonlite)

template_main <- jsonlite::read_json("stacks/devel.json")

# Copy S6_VERSION from rstudio to others.
s6_ver <- template_main$stack[[2]]$ENV$S6_VERSION
## shiny
template_main$stack[[6]]$ENV$S6_VERSION <- s6_ver
## ml
template_main$stack[[10]]$ENV$S6_VERSION <- s6_ver
# Rewrite the template file.
jsonlite::write_json(template_main, "stacks/devel.json", pretty = TRUE, auto_unbox = TRUE)


# Update core-latest-daily
latest_daily <- template_main
latest_daily$TAG <- "latest-daily"
## Only rstudio, tidyverse, verse
latest_daily$stack <- template_main$stack[2:4]
latest_daily$stack[[1]]$FROM <- "rocker/r-ver:latest"
latest_daily$stack[[1]]$ENV$RSTUDIO_VERSION <- "daily"
latest_daily$stack[[2]]$FROM <- "rocker/rstudio:latest-daily"
latest_daily$stack[[3]]$FROM <- "rocker/tidyverse:latest-daily"
# Write the template file.
jsonlite::write_json(latest_daily, "stacks/core-latest-daily.json", pretty = TRUE, auto_unbox = TRUE)

message("sync-template-vers.R done!\n")
