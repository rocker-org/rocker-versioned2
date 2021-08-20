# Definition files for generating Dockerfiles

[Dockerfiles](../dockerfiles) will be generated referring to JSON files in this directory. To update Dockerfiles, first, delete old Dockerfiles with `make clean`, then generate new Dockerfiles with `make setup`.

## Automatic updates

The latest two versions of stack files which exist for each version of R, and theirs template, are automatically updated by [make-stacks.R](../build/make-stacks.R), which is executed daily by GitHub Actions.

- `devel.json`
- `X.Y.Z.json`

See [the build directory](../build) for details.
