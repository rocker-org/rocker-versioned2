# Definition files for generating Dockerfiles

[Dockerfiles](../dockerfiles) will be generated referring to JSON files in this directory. To update Dockerfiles, first, delete old Dockerfiles with `make clean`, then generate new Dockerfiles with `make setup`.

To run `make setup`, you need `jq`, R & the following dependencies locally installed:

1. `fs`
2. `stringr`
3. `purrr`
4. `dplyr`
5. `jsonlite`

## Automatic updates

The latest two versions of stack files which exist for each version of R (`X.Y.Z.json`), and other stack files with alphabetic names, are automatically updated by [make-stacks.R](../build/make-stacks.R), which is executed daily by GitHub Actions.

This means that only stack files with older version numbers can be manually edited without changing the script.

See [the build directory](../build) for details.
