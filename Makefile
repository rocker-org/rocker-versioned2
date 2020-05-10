STACKFILES=$(wildcard stacks/*.json)
STACKS=$(notdir $(basename $(STACKFILES)))
COMPOSEFILES=$(addprefix compose/,$(addsuffix .yml,$(STACKS)))
PUSHES=$(addsuffix .push,$(STACKS))
BUILDKIT_CACHE=0

.PHONY: clean build setup push
.PHONY: $(STACKS) $(PUSHES)

all: clean build push

setup: $(COMPOSEFILES)
$(COMPOSEFILES): make-dockerfiles.R write-compose.R $(STACKFILES)
	./make-dockerfiles.R
	./write-compose.R

build: $(STACKS)

$(STACKS): %: compose/%.yml
	COMPOSE_DOCKER_CLI_BUILD=$(BUILDKIT_CACHE) DOCKER_BUILDKIT=$(BUILDKIT_CACHE) docker-compose -f compose/$@.yml build

binder: geospatial

shiny-4.0.0: core-4.0.0

shiny-3.6.3-ubuntu18.04.json: core-3.6.3-ubuntu18.04.json

geospatial: core-4.0.0 core-devel

geospatial-ubuntu18.04: core-4.0.0-ubuntu18.04

## Assumes we are logged into the Docker Registry already
push: $(PUSHES)

$(PUSHES): %.push: %
	docker-compose -f compose/$<.yml push

clean:
	rm dockerfiles/* compose/*
