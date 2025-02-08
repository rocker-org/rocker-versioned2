#' Write a Dockerfiles with the given template and data frame of variables
#' @param data A data frame of variables.
#' @param ... Ignored.
#' Must have a column named `r_version`.
#' @param dockerfile_template A character of a Dockerfile template
#' @param path_template A character of output Dockerfile path template
#' @return A data frame invisibly.
#' @examples
#' write_dockerfiles(
#'   data.frame(r_version = "4.0.0"),
#'   dockerfile_template = "FROM rocker/r-ver:{{r_version}}",
#'   path_template = "dockerfiles/r-ver_{{r_version}}.Dockerfile"
#' )
write_dockerfiles <- function(data, ..., dockerfile_template, path_template) {
  rlang::check_dots_empty()

  data |>
    dplyr::mutate(
      dockerfile = glue::glue(
        dockerfile_template,
        .open = "{{",
        .close = "}}",
        .trim = FALSE
      )
    ) |>
    purrr::pwalk(
      \(...) {
        dots <- list(...)
        readr::write_file(
          dots$dockerfile,
          glue::glue(
            path_template,
            r_version = dots$r_version,
            .open = "{{",
            .close = "}}",
            .trim = FALSE
          )
        )
      }
    )
}


df_args <- fs::dir_ls(path = "build/args", glob = "*.json") |>
  purrr::map(
    \(x) jsonlite::fromJSON(x, flatten = TRUE) |>
      purrr::modify_if(is.null, \(x) NA) |>
      tibble::as_tibble()
  ) |>
  purrr::list_rbind() |>
  # Limit to the last 2 versions and devel
  utils::tail(3)


tibble::tibble(
  .name = c(
    "r-ver",
    "rstudio",
    "tidyverse",
    "verse",
    "geospatial",
    "shiny",
    "shiny-verse",
    "binder"
  )
) |>
  dplyr::mutate(
    .template_path = glue::glue("build/templates/dockerfiles/{.name}.Dockerfile.txt")
  ) |>
  purrr::pwalk(
    \(...) {
      dots <- rlang::list2(...)
      df_args |>
        write_dockerfiles(
          dockerfile_template = readr::read_file(dots$.template_path),
          path_template = glue::glue(
            "dockerfiles/{dots$.name}_{{{{r_version}}}}.Dockerfile",
            .trim = FALSE
          ),
        )
    }
  )


tibble::tibble(
  r_version = readr::read_tsv("build/variables/r-versions.tsv", show_col_types = FALSE)$r_version |>
    dplyr::last(),
  proj_version = readr::read_tsv("build/variables/proj-versions.tsv", show_col_types = FALSE)$proj_version |>
    dplyr::last(),
  gdal_version = readr::read_tsv("build/variables/gdal-versions.tsv", show_col_types = FALSE)$gdal_version |>
    dplyr::last(),
  geos_version = readr::read_tsv("build/variables/geos-versions.tsv", show_col_types = FALSE)$geos_version |>
    dplyr::last()
) |>
  write_dockerfiles(
    dockerfile_template = readr::read_file("build/templates/dockerfiles/geospatial-dev-osgeo.Dockerfile.txt"),
    path_template = "dockerfiles/geospatial-dev-osgeo.Dockerfile"
  )
