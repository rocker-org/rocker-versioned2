LATEST_TAG=4.1.1

SHELL=/bin/bash
STACKFILES=$(wildcard stacks/*.json)
STACKS=$(notdir $(basename $(STACKFILES)))
COMPOSEFILES=$(addprefix compose/,$(addsuffix .yml,$(STACKS)))
PUSHES=$(addsuffix .push,$(STACKS))

.PHONY: clean build setup push latest
.PHONY: $(STACKS) $(PUSHES)

all: clean build push
latest: clean setup $(LATEST_TAG)


## Alternate way of specifying stacks by group
4.1.1: clean setup 4.1.1
4.1.0: clean setup 4.1.0
4.0.5: clean setup 4.0.5
4.0.4: clean setup 4.0.4
4.0.3: clean setup 4.0.3
4.0.2: clean setup 4.0.2
4.0.1: clean setup 4.0.1
4.0.0: clean setup 4.0.0


setup: ./build/make-dockerfiles.R ./build/write-compose.R ./build/make-bakejson.R $(STACKFILES)
	./build/make-dockerfiles.R
	./build/write-compose.R
	./build/make-bakejson.R


## Builds all stacks
build: $(STACKS)




$(STACKS): %: compose/%.yml
	docker-compose -f compose/$@.yml build
	docker-compose -f compose/$@.yml push



## Dependency order
geospatial-ubuntugis: $(LATEST_TAG)
geospatial-dev-osgeos: $(LATEST_TAG)
geospatial-4.0.0-ubuntu18.04: core-4.0.0-ubuntu18.04


## Assumes we are logged into the Docker Registry already
push: $(PUSHES)

$(PUSHES): %.push: %
	docker-compose -f compose/$<.yml push; \
	./tag.sh $< $(LATEST_TAG)


IMAGE_SOURCE ?= https://github.com/rocker-org/rocker-versioned2
IMAGE_FILTER ?= label=org.opencontainers.image.source=$(IMAGE_SOURCE)
REPORT_SOURCE_ROOT ?= tmp/inspects
IMAGELIST_DIR ?= tmp/imagelist
IMAGELIST_NAME ?= imagelist.tsv
REPORT_DIR ?= reports

## Display the value. ex. print-REPORT_SOURCE_DIR
print-%:
	@echo $* = $($*)


# Set docker-bake.json file path to BAKE_JSON before running `make pull-image-all`.
# ex. $ BAKE_JSON=bakefiles/devel.docker-bake.json make pull-image-all
BAKE_JSON ?= ""
pull-image/%:
	-docker pull $(subst pull-image/, , $@)
pull-image-all: $(foreach I, $(shell jq '.target[].tags[]' -r $(BAKE_JSON) | sed -e 's/:/\\:/g'), pull-image/$(I))


inspect-image/%:
	mkdir -p $(REPORT_SOURCE_ROOT)/$(@F)
	-docker image inspect $(@F) > $(REPORT_SOURCE_ROOT)/$(@F)/docker_inspect.json
	-docker run --rm $(@F) dpkg-query --show --showformat='$${Package}\t$${Version}\n' > $(REPORT_SOURCE_ROOT)/$(@F)/apt_packages.tsv
	-docker run --rm $(@F) Rscript -e 'as.data.frame(installed.packages()[, 3])' > $(REPORT_SOURCE_ROOT)/$(@F)/r_packages.ssv
	-docker run --rm $(@F) python3 -m pip list --disable-pip-version-check > $(REPORT_SOURCE_ROOT)/$(@F)/pip_packages.ssv
inspect-image-all: $(foreach I, $(shell docker image ls -q -f "$(IMAGE_FILTER)"), inspect-image/$(I))
	mkdir -p $(IMAGELIST_DIR)
	docker image ls -f "$(IMAGE_FILTER)" --format "{{.ID}}\t{{.Repository}}\t{{.Tag}}\t{{.CreatedAt}}" > $(IMAGELIST_DIR)/$(IMAGELIST_NAME)

REPORT_SOURCE_DIR := $(wildcard $(REPORT_SOURCE_ROOT)/*)
report/%:
	mkdir -p $(REPORT_DIR)
	-./build/knit-report.R -d ../../$(REPORT_SOURCE_ROOT)/$(@F) $(@F) $(REPORT_DIR)
report-all: $(foreach I, $(REPORT_SOURCE_DIR), report/$(I))

# Move image list to wiki and update Home.md
wiki-home:
	cp -r $(IMAGELIST_DIR) $(REPORT_DIR)
	-Rscript -e 'rmarkdown::render(input = "build/reports/wiki_home.Rmd", output_dir = "$(REPORT_DIR)", output_file = "Home.md")'

clean:
	rm -f dockerfiles/Dockerfile_* compose/*.yml bakefiles/*.json
