#!/usr/bin/env Rscript

library(docopt)
library(rmarkdown)

arguments <- "
Generate a report of container image's infomation.

Usage:
  knit-report.R [-i <inspect_file>] [-a <apt_file>] [-r <r_file>] <image_name> <output_dir>
  knit-report.R [-d <directory_name>] <image_name> <output_dir>

Options:
  -i --inspect    `docker instpect image` output file.
  -a --apt        `dpkg-query --show --showformat='${Package}\\t${Version}\\n'` output file.
  -r --R          `Rscript -e 'as.data.frame(installed.packages()[, 3])` output file.'
  -d --directory  Directory, which contains source files, `docker_inspect.json`, `apt_packages.tsv`, `r_packages.ssv`.

Examples:
  knit-report.R -i tmp/imageid/docker_inspect.json -a tmp/imageid/apt_packages.tsv -r tmp/imageid/r_packages.ssv imageid reports
  knit-report.R -d tmp/imageid imageid reports
" |>
  docopt::docopt()

template <- "build/reports/template.Rmd"

image_name <- arguments$image_name
output_dir <- arguments$output_dir

inspect_file <- arguments$inspect_file
apt_file <- arguments$apt_file
r_file <- arguments$r_file

if(arguments$directory == TRUE) {
  directory <- arguments$directory_name
  inspect_file <- paste0(directory, "/docker_inspect.json")
  apt_file <- paste0(directory, "/apt_packages.tsv")
  r_file <- paste0(directory, "/r_packages.ssv")
}

rmarkdown::render(
  input = template,
  output_dir = output_dir,
  output_file = paste0(arguments$image_name, ".md"),
  params = list(
    image_name = image_name,
    inspect_file = inspect_file,
    apt_file = apt_file,
    r_file = r_file
  )
)
