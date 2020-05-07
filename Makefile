STACKFILES=$(wildcard stacks/*.json)
STACKS=$(notdir $(basename $(STACKFILES)))
COMPOSEFILES=$(addprefix compose/,$(addsuffix .yml,$(STACKS)))
.PHONY: clean build compose setup
.PHONY: $(STACKS)
all: clean build push
setup: $(COMPOSEFILES)
$(COMPOSEFILES): make-dockerfiles.R write-compose.R $(STACKFILES)
	./make-dockerfiles.R
	./write-compose.R	
build: $(STACKS)
$(STACKS): %: compose/%.yml
	docker-compose -f $< build
## Assumes we are logged into the Docker Registry already
push:
	$(foreach comp, $(COMPOSEFILES), docker-compose -f $(comp) push;)
clean:
	rm dockerfiles/* compose/*
