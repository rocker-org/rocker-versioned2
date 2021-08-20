SHELL=/bin/bash

.PHONY: clean setup print-% pull-image% bake-json% inspect-image% report% wiki%

all:

setup:
	./build/make-dockerfiles.R
	./build/write-compose.R
	./build/make-bakejson.R

IMAGE_SOURCE ?= https://github.com/rocker-org/rocker-versioned2
COMMIT_HASH := $(shell git rev-parse HEAD)
IMAGE_REVISION ?= $(COMMIT_HASH)
REPORT_SOURCE_ROOT ?= tmp/inspects
IMAGELIST_DIR ?= tmp/imagelist
IMAGELIST_NAME ?= imagelist.tsv
REPORT_DIR ?= reports

# Display the value.
# ex. $ make print-REPORT_SOURCE_DIR
# ex. $ make print-IMAGE_REVISION
print-%:
	@echo $* = $($*)

# Set docker-bake.json file path to BAKE_JSON before running `make pull-image-all` or `make bake-json-all`.
# ex. $ BAKE_JSONbakefiles/core-latest-daily.docker-bake.json make pull-image-all
BAKE_JSON ?= ""
pull-image/%:
	-docker pull $(subst pull-image/, , $@)
pull-image-all: $(foreach I, $(shell jq '.target[].tags[]' -r $(BAKE_JSON) | sed -e 's/:/\\:/g'), pull-image/$(I))

# docker buildx bake options. When specifying multiple options, please escape spaces with "\".
# ex. $ BAKE_JSON=bakefiles/core-latest-daily.docker-bake.json BAKE_OPTION=--load make bake-json-all
# ex. $ BAKE_JSON=bakefiles/devel.docker-bake.json BAKE_OPTION=--print\ -f\ build/platforms.docker-bake.override.json make bake-json/r-ver
BAKE_OPTION ?= --print
bake-json/%:
	docker buildx bake -f $(BAKE_JSON) --set=*.labels.org.opencontainers.image.revision=$(IMAGE_REVISION) $(BAKE_OPTION) $(@F)
bake-json-all: $(foreach I, $(shell jq '.target | keys_unsorted | .[]' -r $(BAKE_JSON)), bake-json/$(I))


IMAGE_FILTER ?= label=org.opencontainers.image.source=$(IMAGE_SOURCE)
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
	rm -r -f dockerfiles/*.Dockerfile compose/*.yml bakefiles/*.json tmp/*
