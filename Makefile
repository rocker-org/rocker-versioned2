DOCKERFILES=$(wildcard dockerfiles/Dockerfile*)
PARTIALS=$(wildcard partials/*.partial)

TAG=3.6.2-gpu
REGISTRY=docker.pkg.github.com

.PHONY: local_versions images
dockerfiles: $(DOCKERFILES)
all: dockerfiles images

local_versions:
	curl -sL https://bit.ly/2QKF14P > /tmp/versions-grid.csv; echo "\n" >> /tmp/versions-grid.csv; \
	if ! cmp versions-grid.csv /tmp/versions-grid.csv >/dev/null 2>&1; then \
	cp /tmp/versions-grid.csv versions-grid.csv; \
	fi

dockerfiles: 
	./make-dockerfiles.R
	
images: 
	./build-images.R


build: 
	docker build -t rocker/r-ver:${TAG} -f dockerfiles/Dockerfile_r-ver_${TAG} .
	docker build -t rocker/rstudio:${TAG} -f dockerfiles/Dockerfile_rstudio_${TAG} .
	docker build -t rocker/tidyverse:${TAG} -f dockerfiles/Dockerfile_tidyverse_${TAG} .
	docker build -t rocker/verse:${TAG} -f dockerfiles/Dockerfile_verse_${TAG} .
	docker build -t rocker/geospatial:${TAG} -f dockerfiles/Dockerfile_geospatial_${TAG} .
	docker build -t rocker/ml:${TAG} -f dockerfiles/Dockerfile_ml_${TAG} .


clean:
	rm dockerfiles/Dockerfile*.*
