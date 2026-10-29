# Offline integration regression: execute generators in a disposable repository.
root <- normalizePath(".")
load_functions <- function(file, env) {
  for (expr in parse(file)) {
    if (is.call(expr) && identical(expr[[1]], as.name("<-")) &&
        is.call(expr[[3]]) && identical(expr[[3]][[1]], as.name("function"))) eval(expr, env)
  }
}
args_env <- new.env(parent = globalenv())
load_functions("build/scripts/generate-args.R", args_env)
# Capture real URL construction, replacing only HTTP transport.
ns <- asNamespace("httr2")
original <- get("req_perform", ns)
unlockBinding("req_perform", ns)
seen <- character()
assign("req_perform", function(req, ...) {
  seen <<- c(seen, req$url)
  structure(list(status_code = 200L), class = "httr2_response")
}, ns)
stopifnot(args_env$is_rstudio_deb_available("2026.09.0+123", "resolute"))
stopifnot(grepl("/server/jammy/amd64/rstudio-server-2026.09.0-123-amd64.deb$", seen))
assign("req_perform", function(...) stop("mock network failure"), ns)
stopifnot(!args_env$is_rstudio_deb_available("2026.09.0+123", "resolute"))
assign("req_perform", original, ns)
lockBinding("req_perform", ns)
# Exercise installer codename mapping without running any installation commands.
installer <- readLines("scripts/install_rstudio.sh")
first <- grep('^if \\[ "\\$UBUNTU_CODENAME" = "noble"', installer)
last <- grep('^if \\[ "\\$RSTUDIO_VERSION" = "stable"', installer)[1] - 1L
script <- c('UBUNTU_CODENAME=resolute', installer[first:last], 'test "$UBUNTU_CODENAME" = jammy')
stopifnot(system2("bash", c("-c", shQuote(paste(script, collapse = "\n")))) == 0L)

work <- tempfile("release-generation-")
dir.create(work)
for (path in c("build", "dockerfiles", "bakefiles")) {
  stopifnot(file.copy(file.path(root, path), work, recursive = TRUE))
}
setwd(work)
# Pin release inputs so this remains a regression after future releases.
readr::write_tsv(tibble::tibble(
  r_version = c("4.5.3", "4.6.0", "4.6.1", "4.6.2"),
  r_release_date = c("2026-03-11", "2026-04-24", "2026-06-24", "2026-10-29"),
  r_freeze_date = c("2026-04-23", "2026-06-23", "2026-10-28", NA_character_)
), "build/variables/r-versions.tsv", na = "")
args_env$latest_p3m_cran_url_linux <- function(...) "https://example.invalid/cran"
for (available in c(TRUE, FALSE, TRUE)) {
  args_env$is_rstudio_deb_available <- function(...) available
  result <- args_env$rocker_versioned_args()
  latest <- result[result$r_version == "4.6.2", ]
  stopifnot(nrow(latest) == 1L, latest$r_release_date == as.Date("2026-10-29"),
            latest$ubuntu_series == "resolute", is.na(latest$rstudio_version) == !available)
  # Write the actual output through the script's original top-level expressions.
  for (expr in parse(file.path(root, "build/scripts/generate-args.R"))) {
    if (!(is.call(expr) && identical(expr[[1]], as.name("<-")) &&
          is.call(expr[[3]]) && identical(expr[[3]][[1]], as.name("function")))) eval(expr, args_env)
  }
  source(file.path(root, "build/scripts/generate-matrix.R"), local = new.env())
  source(file.path(root, "build/scripts/generate-bakefiles.R"), local = new.env())
  source(file.path(root, "build/scripts/generate-dockerfiles.R"), local = new.env())
  stopifnot("4.6.2" %in% jsonlite::read_json("build/matrix/latest.json", simplifyVector = TRUE)$r_version)
  # Execute the actual core prepare selection, including its empty-array output.
  workflow <- readLines(file.path(root, ".github/workflows/core.yml"))
  first <- grep('^          JSON=build/matrix/latest.json$', workflow)
  last <- grep('echo "rstudio-versions=', workflow, fixed = TRUE)
  selection <- gsub("${{ github.event_name }}", "workflow_dispatch",
                    workflow[first:last], fixed = TRUE)
  matrix_script <- tempfile()
  matrix_output <- tempfile()
  writeLines(c("set -euo pipefail", selection), matrix_script)
  stopifnot(system2("bash", shQuote(matrix_script),
                    env = paste0("GITHUB_OUTPUT=", shQuote(matrix_output))) == 0L)
  output <- readLines(matrix_output)
  versions <- jsonlite::fromJSON(sub("^versions=", "", output[startsWith(output, "versions=")]))
  rstudio_versions <- jsonlite::fromJSON(sub("^rstudio-versions=", "", output[startsWith(output, "rstudio-versions=")]))
  stopifnot(identical(versions, "4.6.2"),
            if (available) identical(rstudio_versions, "4.6.2") else length(rstudio_versions) == 0L)
  unlink(c(matrix_script, matrix_output))
  bake <- jsonlite::read_json("bakefiles/4.6.2.docker-bake.json")
  independent <- c("r-ver", "shiny", "shiny-verse")
  dependent <- c("rstudio", "tidyverse", "verse", "geospatial")
  stopifnot(all(independent %in% names(bake$target)))
  stopifnot(all(vapply(dependent, function(x) (x %in% names(bake$target)) == available, logical(1))))
  for (target in c(independent, dependent)) {
    stopifnot(file.exists(sprintf("dockerfiles/%s_4.6.2.Dockerfile", target)) ==
                (available || target %in% independent))
  }
  # Real publisher configuration succeeds for r-ver and rejects absent RStudio.
  publish <- file.path(root, "build/scripts/core-publish.sh")
  status <- system2("bash", c(publish, "config", "bakefiles/4.6.2.docker-bake.json", "r-ver", "linux/amd64"), stdout = FALSE)
  stopifnot(status == 0L)
  status <- suppressWarnings(system2("bash", c(publish, "config", "bakefiles/4.6.2.docker-bake.json", "rstudio", "linux/amd64"), stdout = FALSE, stderr = FALSE))
  stopifnot((status == 0L) == available)
  stopifnot(file.exists("bakefiles/experimental.docker-bake.json") == available)
}
setwd(root)
unlink(work, recursive = TRUE)
cat("Offline release generation regressions passed\n")
