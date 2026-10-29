# Offline integration regression: execute generators in a disposable repository.
root <- normalizePath(".")
load_functions <- function(file, env) {
  for (expr in parse(file)) {
    if (
      is.call(expr) &&
        identical(expr[[1]], as.name("<-")) &&
        is.call(expr[[3]]) &&
        identical(expr[[3]][[1]], as.name("function"))
    ) {
      eval(expr, env)
    }
  }
}
args_env <- new.env(parent = globalenv())
load_functions("build/scripts/generate-args.R", args_env)
real_checker <- args_env$is_rstudio_deb_available
# Capture real URL construction, replacing only HTTP transport.
ns <- asNamespace("httr2")
original <- get("req_perform", ns)
unlockBinding("req_perform", ns)
seen <- character()
assign(
  "req_perform",
  function(req, ...) {
    seen <<- c(seen, req$url)
    structure(list(status_code = 200L), class = "httr2_response")
  },
  ns
)
stopifnot(args_env$is_rstudio_deb_available("2026.09.0+123", "resolute"))
stopifnot(grepl(
  "/server/jammy/amd64/rstudio-server-2026.09.0-123-amd64.deb$",
  seen
))
assign("req_perform", function(...) stop("mock network failure"), ns)
warning_seen <- FALSE
result <- withCallingHandlers(
  args_env$is_rstudio_deb_available("2026.09.0+123", "resolute"),
  warning = function(w) {
    warning_seen <<- grepl("indeterminate", conditionMessage(w))
    invokeRestart("muffleWarning")
  }
)
stopifnot(is.na(result), warning_seen)
for (status in c(404L, 410L, 503L, 403L)) {
  assign(
    "req_perform",
    function(...) {
      structure(list(status_code = status), class = "httr2_response")
    },
    ns
  )
  warning_seen <- FALSE
  result <- withCallingHandlers(
    args_env$is_rstudio_deb_available("2026.09.0+123", "resolute"),
    warning = function(w) {
      warning_seen <<- grepl("indeterminate", conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  stopifnot(
    if (status %in% c(404L, 410L)) identical(result, FALSE) else is.na(result),
    warning_seen == !status %in% c(404L, 410L)
  )
}
assign("req_perform", original, ns)
lockBinding("req_perform", ns)
# Exercise installer codename mapping without running any installation commands.
installer <- readLines("scripts/install_rstudio.sh")
first <- grep('^if \\[ "\\$UBUNTU_CODENAME" = "noble"', installer)
last <- grep('^if \\[ "\\$RSTUDIO_VERSION" = "stable"', installer)[1] - 1L
script <- c(
  'UBUNTU_CODENAME=resolute',
  installer[first:last],
  'test "$UBUNTU_CODENAME" = jammy'
)
stopifnot(
  system2("bash", c("-c", shQuote(paste(script, collapse = "\n")))) == 0L
)

work <- tempfile("release-generation-")
dir.create(work)
for (path in c("build", "dockerfiles", "bakefiles")) {
  stopifnot(file.copy(file.path(root, path), work, recursive = TRUE))
}
setwd(work)
# Pin release inputs so this remains a regression after future releases.
readr::write_tsv(
  tibble::tibble(
    r_version = c("4.5.3", "4.6.0", "4.6.1", "4.6.2"),
    r_release_date = c("2026-03-11", "2026-04-24", "2026-06-24", "2026-10-29"),
    r_freeze_date = c("2026-04-23", "2026-06-23", "2026-10-28", NA_character_)
  ),
  "build/variables/r-versions.tsv",
  na = ""
)
readr::write_tsv(
  tibble::tibble(
    rstudio_version = c("2026.06.0+242", "2026.10.1+239"),
    rstudio_commit_date = c("2026-06-17", "2026-10-23")
  ),
  "build/variables/rstudio-versions.tsv"
)
readr::write_tsv(
  tibble::tibble(
    ubuntu_version = c("24.04", "26.04"),
    ubuntu_series = c("noble", "resolute"),
    ubuntu_release_date = c("2024-04-25", "2026-04-23")
  ),
  "build/variables/ubuntu-lts-versions.tsv"
)
args_env$latest_p3m_cran_url_linux <- function(...) {
  "https://example.invalid/cran"
}
regenerate <- function() {
  # Write the actual output through the script's original top-level expressions.
  for (expr in parse(file.path(root, "build/scripts/generate-args.R"))) {
    if (
      !(is.call(expr) &&
        identical(expr[[1]], as.name("<-")) &&
        is.call(expr[[3]]) &&
        identical(expr[[3]][[1]], as.name("function")))
    ) {
      eval(expr, args_env)
    }
  }
  source(file.path(root, "build/scripts/generate-matrix.R"), local = new.env())
  source(
    file.path(root, "build/scripts/generate-bakefiles.R"),
    local = new.env()
  )
  source(
    file.path(root, "build/scripts/generate-dockerfiles.R"),
    local = new.env()
  )
}
for (available in c(TRUE, FALSE, TRUE)) {
  args_env$is_rstudio_deb_available <- function(...) available
  result <- args_env$rocker_versioned_args()
  latest <- result[result$r_version == "4.6.2", ]
  stopifnot(
    nrow(latest) == 1L,
    latest$r_release_date == as.Date("2026-10-29"),
    latest$ubuntu_series == "resolute",
    is.na(latest$rstudio_version) == !available
  )
  regenerate()
  stopifnot(
    "4.6.2" %in%
      jsonlite::read_json(
        "build/matrix/latest.json",
        simplifyVector = TRUE
      )$r_version
  )
  # Execute the actual core prepare selection, including its empty-array output.
  workflow <- readLines(file.path(root, ".github/workflows/core.yml"))
  first <- grep('^          JSON=build/matrix/latest.json$', workflow)
  last <- grep('echo "rstudio-versions=', workflow, fixed = TRUE)
  selection <- gsub(
    "${{ github.event_name }}",
    "workflow_dispatch",
    workflow[first:last],
    fixed = TRUE
  )
  matrix_script <- tempfile()
  matrix_output <- tempfile()
  writeLines(c("set -euo pipefail", selection), matrix_script)
  stopifnot(
    system2(
      "bash",
      shQuote(matrix_script),
      env = paste0("GITHUB_OUTPUT=", shQuote(matrix_output))
    ) ==
      0L
  )
  output <- readLines(matrix_output)
  versions <- jsonlite::fromJSON(sub(
    "^versions=",
    "",
    output[startsWith(output, "versions=")]
  ))
  rstudio_versions <- jsonlite::fromJSON(sub(
    "^rstudio-versions=",
    "",
    output[startsWith(output, "rstudio-versions=")]
  ))
  stopifnot(
    identical(versions, "4.6.2"),
    if (available) {
      identical(rstudio_versions, "4.6.2")
    } else {
      length(rstudio_versions) == 0L
    }
  )
  unlink(c(matrix_script, matrix_output))
  bake <- jsonlite::read_json("bakefiles/4.6.2.docker-bake.json")
  independent <- c("r-ver", "shiny", "shiny-verse")
  dependent <- c("rstudio", "tidyverse", "verse", "geospatial")
  stopifnot(all(independent %in% names(bake$target)))
  stopifnot(all(vapply(
    dependent,
    function(x) (x %in% names(bake$target)) == available,
    logical(1)
  )))
  for (target in c(independent, dependent)) {
    stopifnot(
      file.exists(sprintf("dockerfiles/%s_4.6.2.Dockerfile", target)) ==
        (available || target %in% independent)
    )
  }
  # Real publisher configuration succeeds for r-ver and rejects absent RStudio.
  publish <- file.path(root, "build/scripts/core-publish.sh")
  status <- system2(
    "bash",
    c(
      publish,
      "config",
      "bakefiles/4.6.2.docker-bake.json",
      "r-ver",
      "linux/amd64"
    ),
    stdout = FALSE
  )
  stopifnot(status == 0L)
  status <- suppressWarnings(system2(
    "bash",
    c(
      publish,
      "config",
      "bakefiles/4.6.2.docker-bake.json",
      "rstudio",
      "linux/amd64"
    ),
    stdout = FALSE,
    stderr = FALSE
  ))
  stopifnot((status == 0L) == available)
  stopifnot(file.exists("bakefiles/experimental.docker-bake.json") == available)
}
# Mixed release scenario: an existing frozen R must survive an HTTP outage while
# a new R without a verified package still generates independent image targets.
old_args <- readLines("build/args/4.6.1.json")
old_dockerfile <- readLines("dockerfiles/rstudio_4.6.1.Dockerfile")
old_bake <- readLines("bakefiles/4.6.1.docker-bake.json")
history <- readr::read_tsv(
  "build/args/history.tsv",
  show_col_types = FALSE,
  col_types = list(ubuntu_version = readr::col_character())
) |>
  dplyr::filter(r_version != "4.6.2")
readr::write_tsv(history, "build/args/history.tsv", na = "")
old_history <- dplyr::filter(history, r_version == "4.6.1")
unlink("build/args/4.6.2.json")
packages <- readr::read_tsv(
  "build/variables/rstudio-versions.tsv",
  show_col_types = FALSE
) |>
  dplyr::add_row(
    rstudio_version = "2026.10.2+240",
    rstudio_commit_date = as.Date("2026-10-29")
  )
readr::write_tsv(packages, "build/variables/rstudio-versions.tsv")
args_env$is_rstudio_deb_available <- real_checker
unlockBinding("req_perform", ns)
assign(
  "req_perform",
  function(req, ...) {
    status <- if (grepl("2026.10.1-239", req$url, fixed = TRUE)) 503L else 404L
    structure(list(status_code = status), class = "httr2_response")
  },
  ns
)
warnings <- character()
withCallingHandlers(regenerate(), warning = function(w) {
  warnings <<- c(warnings, conditionMessage(w))
  invokeRestart("muffleWarning")
})
assign("req_perform", original, ns)
lockBinding("req_perform", ns)
stopifnot(
  length(warnings) > 0L,
  all(grepl("indeterminate", warnings)),
  identical(readLines("build/args/4.6.1.json"), old_args),
  identical(readLines("dockerfiles/rstudio_4.6.1.Dockerfile"), old_dockerfile),
  identical(readLines("bakefiles/4.6.1.docker-bake.json"), old_bake)
)
new_args <- jsonlite::read_json("build/args/4.6.2.json")
stopifnot(
  is.null(new_args$rstudio_version),
  file.exists("dockerfiles/r-ver_4.6.2.Dockerfile")
)
new_bake <- jsonlite::read_json("bakefiles/4.6.2.docker-bake.json")
stopifnot(
  "r-ver" %in% names(new_bake$target),
  !"rstudio" %in% names(new_bake$target)
)
new_history <- readr::read_tsv(
  "build/args/history.tsv",
  show_col_types = FALSE,
  col_types = list(ubuntu_version = readr::col_character())
)
stopifnot(isTRUE(all.equal(
  dplyr::filter(new_history, r_version == "4.6.1"),
  old_history,
  check.attributes = FALSE
)))
# Devel attempts the latest known package without inheriting stable availability.
stopifnot(
  identical(
    jsonlite::read_json("build/args/devel.json")$rstudio_version,
    "2026.10.2+240"
  ),
  file.exists("dockerfiles/rstudio_devel.Dockerfile")
)
# An indeterminate prior package wins over an older verified candidate. A 404,
# changed distro, or package outside the freeze window must never be retained.
candidates <- tibble::tibble(
  rstudio_version = c("2026.06.0+242", "2026.10.1+239"),
  available = c(TRUE, NA)
)
stopifnot(
  args_env$select_rstudio_version(candidates, "4.6.1", "noble") ==
    "2026.10.1+239"
)
candidates$available[2] <- FALSE
stopifnot(
  args_env$select_rstudio_version(candidates, "4.6.1", "noble") ==
    "2026.06.0+242"
)
candidates$available <- c(FALSE, NA)
stopifnot(
  is.na(args_env$select_rstudio_version(candidates, "4.6.1", "resolute")),
  is.na(args_env$select_rstudio_version(candidates[1, ], "4.6.1", "noble"))
)

# Verify freeze-date eligibility through the real candidate-building pipeline.
previous <- jsonlite::read_json("build/args/4.6.1.json")
ineligible <- previous
ineligible$rstudio_version <- "2026.10.2+240" # committed after the frozen release
jsonlite::write_json(
  ineligible,
  "build/args/4.6.1.json",
  auto_unbox = TRUE,
  pretty = TRUE
)
args_env$is_rstudio_deb_available <- function(...) NA
frozen <- args_env$rocker_versioned_args()
stopifnot(is.na(frozen$rstudio_version[frozen$r_version == "4.6.1"]))
jsonlite::write_json(
  previous,
  "build/args/4.6.1.json",
  auto_unbox = TRUE,
  pretty = TRUE
)

setwd(root)
unlink(work, recursive = TRUE)
cat("Offline release generation regressions passed\n")
