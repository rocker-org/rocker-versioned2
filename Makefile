LATEST_TAG=4.1.0
CUDA=10.1

SHELL=/bin/bash
STACKFILES=$(wildcard stacks/*.json)
STACKS=$(notdir $(basename $(STACKFILES)))
COMPOSEFILES=$(addprefix compose/,$(addsuffix .yml,$(STACKS)))
PUSHES=$(addsuffix .push,$(STACKS))

.PHONY: clean build setup push latest
.PHONY: $(STACKS) $(PUSHES)

all: clean build push
latest: clean setup core-$(LATEST_TAG) geospatial-$(LATEST_TAG) ml-cuda$(CUDA)-$(LATEST_TAG)


## Alternate way of specifying stacks by group
4.1.0: clean setup core-4.1.0 geospatial-4.1.0 binder-4.1.0 shiny-4.1.0 ml-cuda10.1-4.1.0 
4.0.5: clean setup core-4.0.5 geospatial-4.0.5 binder-4.0.5 shiny-4.0.5 ml-cuda10.1-4.0.5
4.0.4: clean setup core-4.0.4 geospatial-4.0.4 binder-4.0.4 shiny-4.0.4 ml-cuda10.1-4.0.4
4.0.3: clean setup core-4.0.3 geospatial-4.0.3 binder-4.0.3 shiny-4.0.3 ml-cuda10.1-4.0.3
4.0.2: clean setup core-4.0.2 geospatial-4.0.2 binder-4.0.2 shiny-4.0.2 ml-cuda10.1-4.0.2
4.0.1: clean setup core-4.0.1 geospatial-4.0.1 binder-4.0.1 shiny-4.0.1 ml-cuda10.1-4.0.1
4.0.0: clean setup core-4.0.0 geospatial-4.0.0 binder-4.0.0 shiny-4.0.0 ml-cuda10.1-4.0.0


setup: $(COMPOSEFILES)
$(COMPOSEFILES): make-dockerfiles.R write-compose.R $(STACKFILES)
	./make-dockerfiles.R
	./write-compose.R


## Builds all stacks
build: $(STACKS)




$(STACKS): %: compose/%.yml
	docker-compose -f compose/$@.yml build
	docker-compose -f compose/$@.yml push



## Dependency order
binder-$(LATEST_TAG): geospatial-$(LATEST_TAG)
shiny-$(LATEST_TAG): core-$(LATEST_TAG)
geospatial-$(LATEST_TAG): core-$(LATEST_TAG) core-devel
geospatial-ubuntugis: core-$(LATEST_TAG)
geospatial-dev-osgeos: core-$(LATEST_TAG)
geospatial-4.0.0-ubuntu18.04: core-4.0.0-ubuntu18.04


## Assumes we are logged into the Docker Registry already
push: $(PUSHES)

$(PUSHES): %.push: %
	docker-compose -f compose/$<.yml push; \
	./tag.sh $< $(LATEST_TAG)



clean:
	rm -f dockerfiles/* compose/*
