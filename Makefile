DOCKERFILES=$(wildcard dockerfiles/Dockerfile*)
COMPOSE=$(wildcard compose/*)

.PHONY: clean
build: $(DOCKERFILES) $(COMPOSE)
push: $(DOCKERFILES) $(COMPOSE)

all: clean setup build push

setup: make-dockerfiles.R write-compose.R 
	./make-dockerfiles.R
	./write-compose.R	

build:
	docker-compose -f compose/core-3.6.3-ubuntu18.04.yml build
	docker-compose -f compose/core-4.0.0.yml build
	docker-compose -f compose/core-devel.yml build
	docker-compose -f compose/core-4.0.0-ubuntu18.04.yml build
	docker-compose -f compose/geospatial.yml build
	docker-compose -f compose/geospatial-ubuntu18.04.yml build
	docker-compose -f compose/ml.yml build
	docker-compose -f compose/binder.yml build
	docker-compose -f compose/shiny-4.0.0.yml build


## Assumes we are logged into the Docker Registry already
push:
	docker-compose -f compose/core-3.6.3-ubuntu18.04.yml build
	docker-compose -f compose/core-4.0.0.yml build
	docker-compose -f compose/core-devel.yml build
	docker-compose -f compose/core-4.0.0-ubuntu18.04.yml build
	docker-compose -f compose/geospatial.yml build
	docker-compose -f compose/geospatial-18.04.yml build
	docker-compose -f compose/ml.yml build
	docker-compose -f compose/binder.yml build
	docker-compose -f compose/shiny-4.0.0.yml build

clean:
	rm dockerfiles/* compose/*
