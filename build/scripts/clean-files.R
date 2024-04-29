remove_unsupported_files <- function(files, supported_versions) {
  files |>
    purrr::discard(
      \(x) stringr::str_detect(x, supported_versions) |> any()
    ) |>
    purrr::walk(
      fs::file_delete
    )
}


supported_versions <- jsonlite::read_json(
  "build/matrix/all.json",
  simplifyVector = TRUE
)$r_version


# Clean up args files
fs::dir_ls(path = "build/args", regexp = r"((\d+\.){3}json)") |>
  remove_unsupported_files(supported_versions)


# Clean up Dockerfiles
fs::dir_ls(path = "dockerfiles", regexp = r"((\d+\.){3}Dockerfile)") |>
  remove_unsupported_files(supported_versions)


# Clean up docker-bake.json files
fs::dir_ls(path = "bakefiles", regexp = r"((\d+\.){3}(extra\.)?docker-bake.json)") |>
  remove_unsupported_files(supported_versions)
