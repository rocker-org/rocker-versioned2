SHELL := /bin/bash

.PHONY: clean test print-% pull-image% bake-json% inspect-% report% wiki%

all:

.PHONY: setup
setup:
	Rscript build/scripts/generate-matrix.R
	Rscript build/scripts/generate-bakefiles.R
	Rscript build/scripts/generate-dockerfiles.R
	Rscript build/scripts/clean-files.R

test: bake-json-test-all bake-json-test-groups


# Test that all targets are in good format.
bake-json-test/%:
	docker buildx bake -f $(patsubst %/,%,$(dir $*)) --print $(notdir $*)
bake-json-test-all: $(foreach json, $(wildcard bakefiles/*.docker-bake.json), $(foreach target, $(shell jq '.target | keys_unsorted | .[]' -r $(json)), bake-json-test/$(json)/$(target)))
bake-json-test-groups: $(foreach json, $(wildcard bakefiles/*.docker-bake.json), $(foreach target, $(shell jq '.group[] | keys[]' -r $(json)), bake-json-test/$(json)/$(target)))


IMAGE_SOURCE ?= https://github.com/rocker-org/rocker-versioned2
COMMIT_HASH := $(shell git rev-parse HEAD)
IMAGE_REVISION ?= $(COMMIT_HASH)

# Display the value.
# ex. $ make print-REPORT_SOURCE_DIR
# ex. $ make print-IMAGE_REVISION
print-%:
	@echo $* = $($*)

# Set docker-bake.json file path to BAKE_JSON before running `make pull-image-all` or `make bake-json-all`, `make bake-json-group`.
# ex. $ BAKE_JSONbakefiles/core-latest-daily.docker-bake.json make pull-image-all
BAKE_JSON ?= ""
BAKE_GROUP ?= default

pull-image/%:
	-docker pull $*
pull-image-all: $(foreach I, $(shell jq '.target[].tags[]' -r $(BAKE_JSON) | sed -e 's/:/\\:/g'), pull-image/$(I))
pull-image-group: $(foreach I, $(shell docker buildx bake --print -f $(BAKE_JSON) $(BAKE_GROUP) | jq '.target[].tags[]' | sed -e 's/:/\\:/g'), pull-image/$(I))

# docker buildx bake options. When specifying multiple options, please escape spaces with "\".
# ex. $ BAKE_JSON=bakefiles/core-latest-daily.docker-bake.json BAKE_OPTION=--load make bake-json-all
# ex. $ BAKE_JSON=bakefiles/devel.docker-bake.json BAKE_OPTION=--load\ --no-cache make bake-json/r-ver
BAKE_OPTION ?= --print
bake-json/%:
	docker buildx bake -f $(BAKE_JSON) --set=*.labels.org.opencontainers.image.revision=$(IMAGE_REVISION) $(BAKE_OPTION) $*
bake-json-all: $(foreach I, $(shell jq '.target | keys_unsorted | .[]' -r $(BAKE_JSON)), bake-json/$(I))
bake-json-group: $(foreach I, $(shell jq '.group[]."$(BAKE_GROUP)"[].targets[]' -r $(BAKE_JSON)), bake-json/$(I))


# Inspect R container images by `make inspect-image-all` and generate reports about them by `make report-all`.
REPORT_SOURCE_ROOT ?= tmp/inspects
IMAGELIST_DIR ?= tmp/imagelist
IMAGELIST_NAME ?= imagelist.tsv
REPORT_DIR ?= reports
IMAGE_FILTER ?= label=org.opencontainers.image.source=$(IMAGE_SOURCE)
inspect-image/%:
	mkdir -p $(REPORT_SOURCE_ROOT)/$*
	-docker image inspect $* > $(REPORT_SOURCE_ROOT)/$*/docker_inspect.json
	-docker run --rm $* dpkg-query --show --showformat='$${Package}\t$${Version}\t$${Status}\n' > $(REPORT_SOURCE_ROOT)/$*/apt_packages.tsv
	-docker run --rm $* Rscript -e 'as.data.frame(installed.packages()[, 3])' > $(REPORT_SOURCE_ROOT)/$*/r_packages.ssv
	-docker run --rm $* python3 -m pip list --disable-pip-version-check > $(REPORT_SOURCE_ROOT)/$*/pip_packages.ssv
inspect-manifest/%: inspect-image/%
	-$(foreach I, $(shell jq '.[].RepoDigests[]' -r $(REPORT_SOURCE_ROOT)/$*/docker_inspect.json), $(shell docker buildx imagetools inspect $(I) >> $(REPORT_SOURCE_ROOT)/$*/imagetools_inspect.txt))
inspect-image-all: $(foreach I, $(shell docker image ls -q -f "$(IMAGE_FILTER)"), inspect-manifest/$(I))
	mkdir -p $(IMAGELIST_DIR)
	docker image ls -f "$(IMAGE_FILTER)" --format "{{.ID}}\t{{.Repository}}\t{{.Tag}}\t{{.CreatedAt}}" > $(IMAGELIST_DIR)/$(IMAGELIST_NAME)

report/%:
	mkdir -p $(REPORT_DIR)
	-./build/knit-report.R -d $* $(@F) $(REPORT_DIR)
report-all: $(foreach I, $(wildcard $(REPORT_SOURCE_ROOT)/*), report/$(I))


# Move image list to wiki and update Home.md
wiki-home: $(REPORT_DIR)/Versions.md $(REPORT_DIR)/_Sidebar.md
	cp -r $(IMAGELIST_DIR) $(REPORT_DIR)
	Rscript -e 'rmarkdown::render(input = "build/reports/wiki_home.Rmd", output_dir = "$(REPORT_DIR)", output_file = "Home.md")'
$(REPORT_DIR)/_Sidebar.md: build/reports/_Sidebar.md
	cp $< $@
$(REPORT_DIR)/Versions.md: build/reports/versions.Rmd build/args/history.tsv
	-Rscript -e 'rmarkdown::render(input = "$<", output_dir = "$(@D)", output_file = "$(@F)")'

clean:
	rm -r -f tmp/*
