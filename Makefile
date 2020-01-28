DOCKERFILES=$(wildcard dockerfiles/Dockerfile*)
PARTIALS=$(wildcard partials/*.partial)

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
	docker build -t rocker/r-ver:3.6.2-gpu -f dockerfiles/Dockerfile_r-ver_3.6.2-gpu .
	docker build -t rocker/rstudio:3.6.2-gpu -f dockerfiles/Dockerfile_rstudio_3.6.2-gpu .
	docker build -t rocker/tidyverse:3.6.2-gpu -f dockerfiles/Dockerfile_tidyverse_3.6.2-gpu .
	docker build -t rocker/verse:3.6.2-gpu -f dockerfiles/Dockerfile_verse_3.6.2-gpu .
	docker build -t rocker/geospatial:3.6.2-gpu -f dockerfiles/Dockerfile_geospatial_3.6.2-gpu .
	docker build -t rocker/ml:3.6.2-gpu -f dockerfiles/Dockerfile_ml_3.6.2-gpu .


