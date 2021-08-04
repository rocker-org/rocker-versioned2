#!/usr/bin/env Rscript

library(docopt)
library(rmarkdown)

arguments <- "
Generate a report of container image's infomation.

Usage:
  knit-report.R [-i <inspect_file>] [-a <apt_file>] [-r <r_file>] <image_name>
  knit-report.R <image_name>

Options:
  -i --inspect  `docker instpect image` output file.
  -a --apt      `dpkg-query --show --showformat='${Package}\\t${Version}\\n'` output file.
  -r --R        `Rscript -e 'as.data.frame(installed.packages()[, 3])` output file.'
" |>
  docopt::docopt()

template <- "build/reports/template.Rmd"

inspect_file <- arguments$inspect_file
apt_file <- arguments$apt_file
r_file <- arguments$r_file

rmarkdown::render(
  input = template,
  output_file = paste0(arguments$image_name, ".md"),
  params = list(
    image_name = arguments$image_name,
    inspect_file = inspect_file,
    apt_file = apt_file,
    r_file = r_file
  )
)
