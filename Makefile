
STACKFILES=$(wildcard stacks/*.json)
STACKS=$(notdir $(basename $(STACKFILES)))
COMPOSEFILES=$(addprefix compose/,$(addsuffix .yml,$(STACKS)))
.PHONY: clean build compose setup
.PHONY: $(STACKS)
all: clean build push

build: $(STACKS)

setup: $(COMPOSEFILES)
$(COMPOSEFILES): make-dockerfiles.R write-compose.R $(STACKFILES)
	./make-dockerfiles.R
	./write-compose.R
$(STACKS): %: compose/%.yml
	docker-compose -f compose/$@.yml build
binder: geospatial
	docker-compose -f compose/$@.yml build
shiny-4.0.0: core-4.0.0
	docker-compose -f compose/$@.yml build
shiny-3.6.3: core-3.6.3
	docker-compose -f compose/$@.yml build
geospatial: core-4.0.0 core-devel
geospatial-ubuntu18.04.json: core-4.0.0-ubuntu18.04.json
	docker-compose -f compose/$@.yml build
## Assumes we are logged into the Docker Registry already
push:
	$(foreach comp, $(COMPOSEFILES), docker-compose -f $(comp) push;)
clean:
	rm dockerfiles/* compose/*


