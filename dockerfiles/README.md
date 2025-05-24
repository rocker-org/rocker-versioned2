# Dockerfiles for container images on Docker Hub

:warning: Dockerfiles in this directory are generated from the stack files by [`generate-dockerfiles.R`](../build/scripts/generate-dockerfiles.R). **Don't edit manually.** :warning:

## Build container images by yourself

Building container images with GitHub Actions is done via the [`Makefile`](../Makefile) with the `docker buildx bake` command to control tags, labels, and platforms.

To build a container image for your local use, a simple command like the one below should be fine.

```shell
docker build . -f dockerfiles/rstudio_latest-daily.Dockerfile -t imagename
```
