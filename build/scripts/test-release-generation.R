# Offline regressions for package checks, release independence, and outage safety.
run_tests <- function() {
  root <- normalizePath(".")
  source("build/scripts/generate-args.R", local = TRUE)

  # The real URL builder and HTTP classification with an injected transport.
  for (status in c(200L, 404L, 410L, 503L)) {
    warned <- FALSE
    result <- withCallingHandlers(
      is_rstudio_deb_available(
        "2026.10.1+239",
        "resolute",
        perform = function(req) {
          stopifnot(identical(
            req$url,
            "https://download2.rstudio.org/server/jammy/amd64/rstudio-server-2026.10.1-239-amd64.deb"
          ))
          structure(list(status_code = status), class = "httr2_response")
        }
      ),
      warning = function(w) {
        warned <<- grepl("indeterminate", conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    )
    stopifnot(
      identical(
        result,
        switch(
          as.character(status),
          "200" = TRUE,
          "404" = FALSE,
          "410" = FALSE,
          "503" = NA
        )
      ),
      warned == (status == 503L)
    )
  }
  stopifnot(is.na(suppressWarnings(is_rstudio_deb_available(
    "2026.10.1+239",
    "resolute",
    perform = function(req) stop("offline")
  ))))

  work <- tempfile("release-generation-")
  dir.create(work)
  on.exit(
    {
      setwd(root)
      unlink(work, recursive = TRUE)
    },
    add = TRUE
  )
  file.copy(file.path(root, "build"), work, recursive = TRUE)
  setwd(work)
  dir.create("bakefiles")
  dir.create("dockerfiles")
  unlink(list.files("build/args", pattern = "\\.json$", full.names = TRUE))
  history <- readr::read_tsv(
    "build/args/history.tsv",
    show_col_types = FALSE,
    col_types = list(ubuntu_version = readr::col_character())
  )
  readr::write_tsv(
    history[history$r_version == "4.6.1", ],
    "build/args/history.tsv"
  )
  readr::write_tsv(
    tibble::tibble(
      r_version = c("4.5.3", "4.6.1", "4.6.2"),
      r_release_date = c("2026-03-11", "2026-06-24", "2026-10-29"),
      r_freeze_date = c("2026-04-23", "2026-10-28", NA_character_)
    ),
    "build/variables/r-versions.tsv",
    na = ""
  )
  readr::write_tsv(
    tibble::tibble(
      ubuntu_version = c("24.04", "26.04"),
      ubuntu_series = c("noble", "resolute"),
      ubuntu_release_date = c("2024-04-25", "2026-04-23")
    ),
    "build/variables/ubuntu-lts-versions.tsv"
  )
  readr::write_tsv(
    tibble::tibble(
      rstudio_version = c("2026.04.0+526", "2026.10.1+239", "2026.10.2+240"),
      rstudio_commit_date = c("2026-04-17", "2026-10-23", "2026-10-29")
    ),
    "build/variables/rstudio-versions.tsv"
  )
  regenerate <- function(check) {
    generate_args(check_rstudio = check, cran_url = function(...) {
      "https://example.invalid/cran"
    })
    source(file.path(root, "build/scripts/generate-matrix.R"), local = TRUE)
    source(file.path(root, "build/scripts/generate-bakefiles.R"), local = TRUE)
    source(
      file.path(root, "build/scripts/generate-dockerfiles.R"),
      local = TRUE
    )
  }
  read_bake <- function(version) {
    jsonlite::read_json(paste0("bakefiles/", version, ".docker-bake.json"))
  }
  aliases <- function(bake, target, version) {
    stopifnot(all(
      paste0(
        "docker.io/rocker/",
        target,
        ":",
        c(version, sub("\\.\\d+$", "", version), "4", "latest")
      ) %in%
        unlist(bake$target[[target]]$tags)
    ))
  }

  # A missing RStudio package must not suppress the new R, its matrix, or aliases.
  regenerate(function(...) TRUE)
  aliases(read_bake("4.6.2"), "r-ver", "4.6.2")
  aliases(read_bake("4.6.2"), "rstudio", "4.6.2")
  supported <- function(version, series) {
    version == "2026.10.1+239" && series == "noble"
  }
  regenerate(supported)
  latest <- jsonlite::read_json("build/args/4.6.2.json")
  stopifnot(
    latest$r_release_date == "2026-10-29",
    latest$ubuntu_series == "resolute",
    is.null(latest$rstudio_version),
    "4.6.2" %in%
      jsonlite::read_json(
        "build/matrix/latest.json",
        simplifyVector = TRUE
      )$r_version
  )
  stopifnot(
    identical(
      names(read_bake("4.6.2")$target),
      c("r-ver", "shiny", "shiny-verse")
    ),
    file.exists("dockerfiles/r-ver_4.6.2.Dockerfile"),
    !file.exists("dockerfiles/rstudio_4.6.2.Dockerfile")
  )
  aliases(read_bake("4.6.2"), "r-ver", "4.6.2")
  for (target in c("rstudio", "tidyverse", "verse", "geospatial")) {
    aliases(read_bake("4.6.1"), target, "4.6.1")
  }
  publisher <- file.path(root, "build/scripts/core-publish.sh")
  stopifnot(
    system2(
      "bash",
      c(
        publisher,
        "config",
        "bakefiles/4.6.2.docker-bake.json",
        "r-ver",
        "linux/amd64"
      ),
      stdout = FALSE
    ) ==
      0L,
    system2(
      "bash",
      c(
        publisher,
        "config",
        "bakefiles/4.6.2.docker-bake.json",
        "rstudio",
        "linux/amd64"
      ),
      stdout = FALSE,
      stderr = FALSE
    ) !=
      0L
  )

  # An outage preserves existing released definitions/history but cannot validate
  # a new release, a different distro, or a package outside the freeze window.
  preserved <- c(
    "build/args/4.6.1.json",
    "dockerfiles/rstudio_4.6.1.Dockerfile",
    "bakefiles/4.6.1.docker-bake.json"
  )
  before <- lapply(preserved, readLines)
  history <- readLines("build/args/history.tsv")
  old_history <- history[startsWith(history, "4.6.1\t")]
  unlink("build/args/4.6.2.json")
  regenerate(function(version, series) {
    if (supported(version, series)) NA else FALSE
  })
  stopifnot(
    identical(before, lapply(preserved, readLines)),
    identical(
      old_history,
      readLines("build/args/history.tsv")[startsWith(
        readLines("build/args/history.tsv"),
        "4.6.1\t"
      )]
    ),
    file.exists("dockerfiles/r-ver_4.6.2.Dockerfile"),
    !file.exists("dockerfiles/rstudio_4.6.2.Dockerfile")
  )
  candidates <- tibble::tibble(
    rstudio_version = "2026.10.1+239",
    available = NA
  )
  stopifnot(is.na(select_rstudio_version(candidates, "4.6.1", "resolute")))
  previous <- jsonlite::read_json("build/args/4.6.1.json")
  previous$rstudio_version <- "2026.10.2+240"
  jsonlite::write_json(previous, "build/args/4.6.1.json", auto_unbox = TRUE)
  frozen <- rocker_versioned_args(
    check_rstudio = function(...) NA,
    cran_url = function(...) "mock"
  )
  stopifnot(is.na(frozen$rstudio_version[frozen$r_version == "4.6.1"]))
  # Alias owners outside the two newest R versions must also be refreshed.
  releases <- readr::read_tsv(
    "build/variables/r-versions.tsv",
    show_col_types = FALSE
  ) |>
    dplyr::add_row(
      r_version = "4.6.3",
      r_release_date = as.Date("2026-11-01"),
      r_freeze_date = as.Date(NA)
    )
  readr::write_tsv(releases, "build/variables/r-versions.tsv", na = "")
  stopifnot(!file.exists("dockerfiles/rstudio_4.5.3.Dockerfile"))
  unlink("dockerfiles/r-ver_4.6.1.Dockerfile")
  regenerate(function(version, series) {
    version == "2026.04.0+526" && series == "noble"
  })
  recovered <- read_bake("4.5.3")
  for (target in c("rstudio", "tidyverse", "verse", "geospatial")) {
    stopifnot(file.exists(recovered$target[[target]]$dockerfile))
  }
  stopifnot(
    !file.exists("dockerfiles/r-ver_4.6.1.Dockerfile"),
    file.exists("dockerfiles/r-ver_devel.Dockerfile")
  )
  aliases(recovered, "rstudio", "4.5.3")
  aliases(read_bake("4.6.3"), "r-ver", "4.6.3")
  cat("Offline release generation regressions passed\n")
}
run_tests()
