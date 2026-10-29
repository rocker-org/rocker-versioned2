default_labels <- list(
  org.opencontainers.image.licenses = "GPL-2.0-or-later",
  org.opencontainers.image.source = "https://github.com/rocker-org/rocker-versioned2",
  org.opencontainers.image.vendor = "Rocker Project",
  org.opencontainers.image.authors = "Carl Boettiger <cboettig@ropensci.org>"
)

#' @param ... Named arguments
#' @param bakefile_template A character of a template for docker-bake.json
#' @param path_template A character of output path template
#' @return A data frame invisibly.
#' @examples
#' write_main_bakefile(
#'   r_version = "4.0.0",
#'   ubuntu_series = "focal",
#'   r_minor_latest = TRUE,
#'   r_major_latest = TRUE,
#'   bakefile_template = r"({"target": {"r-ver": {"dockerfile": "dockerfiles/r-ver_{{r_version}}.Dockerfile"}}})",
#'   path_template = "bakefiles/{{r_version}}.docker-bake.json"
#' )
write_main_bakefile <- function(..., bakefile_template, path_template) {
  dots <- rlang::list2(...)
  bake_json_content <- glue::glue_data(
    dots,
    bakefile_template,
    .open = "{{",
    .close = "}}",
    .trim = FALSE
  ) |>
    jsonlite::fromJSON(simplifyVector = FALSE)

  # Older argument files have only the shared alias flags.
  if (is.null(dots$rstudio_minor_latest)) dots$rstudio_minor_latest <- dots$r_minor_latest
  if (is.null(dots$rstudio_major_latest)) dots$rstudio_major_latest <- dots$r_major_latest

  generate_versioned_tags <- function(base_name, rstudio = FALSE) {
    generate_tags(
      base_name,
      r_version = dots$r_version,
      r_minor_latest = if (rstudio) dots$rstudio_minor_latest else dots$r_minor_latest,
      r_major_latest = if (rstudio) dots$rstudio_major_latest else dots$r_major_latest
    ) |>
      as.list()
  }

  # Update labels, tags
  # TODO: Do not repeat these
  ## r-ver
  bake_json_content$target$`r-ver`$labels <- c(
    bake_json_content$target$`r-ver`$labels,
    default_labels
  )
  bake_json_content$target$`r-ver`$tags <- c("docker.io/rocker/r-ver", "ghcr.io/rocker-org/r-ver") |>
    generate_versioned_tags()

  ## rstudio
  bake_json_content$target$rstudio$labels <- c(
    bake_json_content$target$rstudio$labels,
    default_labels
  )
  bake_json_content$target$rstudio$tags <- c("docker.io/rocker/rstudio", "ghcr.io/rocker-org/rstudio") |>
    generate_versioned_tags(rstudio = TRUE)

  ## tidyverse
  bake_json_content$target$tidyverse$labels <- c(
    bake_json_content$target$tidyverse$labels,
    default_labels
  )
  bake_json_content$target$tidyverse$tags <- c("docker.io/rocker/tidyverse", "ghcr.io/rocker-org/tidyverse") |>
    generate_versioned_tags(rstudio = TRUE)

  ## verse
  bake_json_content$target$verse$labels <- c(
    bake_json_content$target$verse$labels,
    default_labels
  )
  bake_json_content$target$verse$tags <- c("docker.io/rocker/verse", "ghcr.io/rocker-org/verse") |>
    generate_versioned_tags(rstudio = TRUE)

  ## geospatial
  bake_json_content$target$geospatial$labels <- c(
    bake_json_content$target$geospatial$labels,
    default_labels
  )
  bake_json_content$target$geospatial$tags <- c("docker.io/rocker/geospatial", "ghcr.io/rocker-org/geospatial") |>
    generate_versioned_tags(rstudio = TRUE)

  ## shiny
  bake_json_content$target$shiny$labels <- c(
    bake_json_content$target$shiny$labels,
    default_labels
  )
  bake_json_content$target$shiny$tags <- c("docker.io/rocker/shiny", "ghcr.io/rocker-org/shiny") |>
    generate_versioned_tags()

  ## shiny-verse
  bake_json_content$target$`shiny-verse`$labels <- c(
    bake_json_content$target$`shiny-verse`$labels,
    default_labels
  )
  bake_json_content$target$`shiny-verse`$tags <- c("docker.io/rocker/shiny-verse", "ghcr.io/rocker-org/shiny-verse") |>
    generate_versioned_tags()

  # Update cache-from
  bake_json_content$target$`r-ver`$`cache-from` <-
    bake_json_content$target$rstudio$`cache-from` <-
    bake_json_content$target$tidyverse$`cache-from` <-
    bake_json_content$target$verse$`cache-from` <-
    bake_json_content$target$geospatial$`cache-from` <-
    bake_json_content$target$shiny$`cache-from` <-
    bake_json_content$target$`shiny-verse`$`cache-from` <-
    c(
      bake_json_content$target$`r-ver`$tags,
      bake_json_content$target$rstudio$tags,
      bake_json_content$target$tidyverse$tags,
      bake_json_content$target$verse$tags,
      bake_json_content$target$geospatial$tags,
      bake_json_content$target$shiny$tags,
      bake_json_content$target$`shiny-verse`$tags
    )

  if (is.null(dots$rstudio_version) || is.na(dots$rstudio_version)) {
    unavailable <- c("rstudio", "tidyverse", "verse", "geospatial")
    bake_json_content$target[unavailable] <- NULL
    targets <- bake_json_content$group[[1]]$default[[1]]$targets
    bake_json_content$group[[1]]$default[[1]]$targets <- targets[!targets %in% unavailable]
  }

  jsonlite::write_json(
    bake_json_content,
    path = glue::glue_data(
      dots,
      path_template,
      .open = "{{",
      .close = "}}"
    ),
    pretty = TRUE,
    auto_unbox = TRUE
  )
}

write_experimental_bakefile <- function(..., bakefile_template, path_template) {
  dots <- rlang::list2(...)

  glue::glue_data(
    dots,
    bakefile_template,
    .open = "{{",
    .close = "}}",
    .trim = FALSE
  ) |>
    jsonlite::fromJSON(simplifyVector = FALSE) |>
    jsonlite::write_json(
      path = glue::glue_data(
        dots,
        path_template,
        .open = "{{",
        .close = "}}"
      ),
      pretty = TRUE,
      auto_unbox = TRUE
    )
}


#' Outer paste of vectors
#' @param ... Character vectors to paste
#' @return A character vector
#' @examples
#' outer_paste("foo", c("-", "+"), c("bar", "baz"))
outer_paste <- function(...) {
  rlang::list2(...) |>
    purrr::reduce(\(x, y) {
      outer(x, y, stringr::str_c) |> c()
    })
}


generate_tags <- function(base_name,
                          ...,
                          r_version,
                          r_minor_latest = FALSE,
                          r_major_latest = FALSE,
                          use_latest_tag = TRUE,
                          tag_suffix = "",
                          latest_tag = "latest") {
  rlang::check_dots_empty()

  .tags <- outer_paste(base_name, ":", r_version, tag_suffix)

  r_minor_version <- stringr::str_extract(r_version, "^\\d+\\.\\d+")
  r_major_version <- stringr::str_extract(r_version, "^\\d+")

  if (isTRUE(r_minor_latest)) {
    .tags <- c(.tags, outer_paste(base_name, ":", r_minor_version, tag_suffix))
  }
  if (isTRUE(r_major_latest)) {
    .tags <- c(.tags, outer_paste(base_name, ":", r_major_version, tag_suffix))
    if (isTRUE(use_latest_tag)) {
      .tags <- c(.tags, outer_paste(base_name, ":", latest_tag))
    }
  }

  .tags
}


df_args <- fs::dir_ls(path = "build/args", regexp = r"((\d+\.){3}json)") |>
  purrr::map(
    \(x) jsonlite::fromJSON(x, flatten = TRUE) |>
      purrr::modify_if(is.null, \(x) NA) |>
      tibble::as_tibble()
  ) |>
  purrr::list_rbind() |>
  dplyr::arrange(as.numeric_version(r_version))

# RStudio aliases follow the latest supported R with a usable RStudio package.
df_rstudio_aliases <- df_args |>
  dplyr::filter(
    !is.na(rstudio_version),
    r_version %in% jsonlite::read_json("build/matrix/all.json", simplifyVector = TRUE)$r_version
  ) |>
  dplyr::mutate(
    minor = stringr::str_extract(r_version, "^\\d+\\.\\d+"),
    major = stringr::str_extract(r_version, "^\\d+")
  ) |>
  dplyr::mutate(rstudio_minor_latest = dplyr::row_number() == dplyr::n(), .by = minor) |>
  dplyr::mutate(rstudio_major_latest = dplyr::row_number() == dplyr::n(), .by = major) |>
  dplyr::select(r_version, rstudio_minor_latest, rstudio_major_latest)

df_args <- df_args |>
  dplyr::left_join(df_rstudio_aliases, by = "r_version") |>
  # Refresh both recent R versions and older supported RStudio alias owners.
  dplyr::filter(
    r_version %in% utils::tail(df_args$r_version, 2) |
      rstudio_minor_latest %in% TRUE | rstudio_major_latest %in% TRUE
  )

df_args |>
  purrr::pwalk(
    \(...) {
      write_main_bakefile(
        ...,
        bakefile_template = readr::read_file("build/templates/bakefiles/main.docker-bake.json"),
        path_template = "bakefiles/{{r_version}}.docker-bake.json"
      )
    }
  )

# Experimental images' bake files
df_args |>
  utils::tail(1) |>
  dplyr::filter(!is.na(rstudio_version)) |>
  purrr::pwalk(
    \(...) {
      write_experimental_bakefile(
        ...,
        bakefile_template = readr::read_file("build/templates/bakefiles/experimental.docker-bake.json"),
        path_template = "bakefiles/experimental.docker-bake.json"
      )
    }
  )

if (is.na(tail(df_args$rstudio_version, 1))) {
  unlink("bakefiles/experimental.docker-bake.json")
}
