STACKFILES=$(wildcard stacks/*.json)
STACKS=$(notdir $(basename $(STACKFILES)))
COMPOSEFILES=$(addprefix compose/,$(addsuffix .yml,$(STACKS)))
PUSHES=$(addsuffix .push,$(STACKS))

.PHONY: clean build setup push
.PHONY: $(STACKS) $(PUSHES)

all: clean build push

setup: $(COMPOSEFILES)
$(COMPOSEFILES): make-dockerfiles.R write-compose.R $(STACKFILES)
	./make-dockerfiles.R
	./write-compose.R

build: $(STACKS)

$(STACKS): %: compose/%.yml
	docker-compose -f compose/$@.yml build

binder: geospatial
	docker-compose -f compose/$@.yml build

shiny-4.0.0: core-4.0.0
	docker-compose -f compose/$@.yml build

shiny-3.6.3: core-3.6.3
	docker-compose -f compose/$@.yml build

geospatial: core-4.0.0 core-devel

geospatial-ubuntu18.04: core-4.0.0-ubuntu18.04
	docker-compose -f compose/$@.yml build

## Assumes we are logged into the Docker Registry already
push: $(PUSHES)

$(PUSHES): %.push: %
	docker-compose -f compose/$<.yml push

clean:
	rm dockerfiles/* compose/*
