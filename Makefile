
CURRENT_UID = $(shell id -u):$(shell id -g)
DIST_DIR ?= $(CURDIR)/dist
REPOSITORY_NAME ?= curriculum_vitae
REPOSITORY_OWNER ?= roybaptiste
REPOSITORY_BASE_URL ?= https://github.com/$(REPOSITORY_OWNER)/$(REPOSITORY_NAME)
OWNER_NAME ?= "Baptiste Roy"
SHORT_OWNER_NAME ?= $(shell echo "$(OWNER_NAME)" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

### TRAVIS_BRANCH == TRAVIS_TAG when a build is triggered by a tag as per https://docs.travis-ci.com/user/environment-variables/
ifndef TRAVIS_BRANCH
# For running outside Travis
TRAVIS_BRANCH = $(shell git rev-parse --abbrev-ref HEAD)
endif

SOURCE_URL = $(REPOSITORY_BASE_URL)/tree/$(TRAVIS_BRANCH)

ifneq ($(TRAVIS_BRANCH), master)
CV_URL = https://$(REPOSITORY_OWNER).github.io/$(REPOSITORY_NAME)/$(TRAVIS_BRANCH)
else
CV_URL = https://$(REPOSITORY_OWNER).github.io/$(REPOSITORY_NAME)
endif

export CV_URL REPOSITORY_URL REPOSITORY_BASE_URL TRAVIS_BRANCH \
	CURRENT_UID SOURCE_URL SHORT_OWNER_NAME

.PHONY: all
all: clean build test

$(DIST_DIR):
	mkdir -p $(DIST_DIR)

.PHONY: build
build: html pdf

.PHONY: html
html: $(DIST_DIR)
	docker-compose up html

.PHONY: pdf
pdf: $(DIST_DIR)
	docker-compose up pdf

.PHONY: clean
clean:
	rm -rf $(DIST_DIR)

.PHONY: test
test: $(DIST_DIR)/index.html
	docker run --rm -v $(DIST_DIR):/dist --user $(CURRENT_UID) 18fgsa/html-proofer \
		--check-html \
		--http-status-ignore "999" \
		--url-ignore "/localhost:/,/127.0.0.1:/" \
		/dist/index.html

.PHONY: distoy
deploy:
	rm -rf $(DEPLOY_DIR)
	git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
	git fetch --unshallow origin $(DEPLOY_BRANCH) || git fetch origin --prune
	git worktree remove $(DEPLOY_DIR) --force 2>/dev/null || true
	@echo "Deploy Done"
