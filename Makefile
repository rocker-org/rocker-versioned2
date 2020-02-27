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
	docker-compose build

clean:
	rm dockerfiles/Dockerfile*.*
