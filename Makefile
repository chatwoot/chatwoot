SHELL := bash

ifdef TERM
	bold := $(shell tput bold)
	sgr0 := $(shell tput sgr0)
endif

APP_GIT_URL		:= $(shell git -C '$(CURDIR)' remote get-url origin)
REPO_ORG		:= $(shell [[ '$(APP_GIT_URL:%.git=%)' =~ ([^/:]+)/([^/]+)$$ ]] && echo "$${BASH_REMATCH[1]}")
REPO_NAME		:= $(shell [[ '$(APP_GIT_URL:%.git=%)' =~ ([^/:]+)/([^/]+)$$ ]] && echo "$${BASH_REMATCH[2]}")
GIT_COMMIT		?= $(shell git -C '$(CURDIR)' log -1 --pretty=%H)
BUILD_NUMBER	?= 0


# gitlab shim
ifdef CI_PIPELINE_ID
	BUILD_NUMBER := $(CI_PIPELINE_ID)
endif
ifdef CI_MERGE_REQUEST_IID
	CHANGE_ID := $(CI_MERGE_REQUEST_IID)
endif
ifdef CI_COMMIT_BRANCH
	GIT_BRANCH := $(CI_COMMIT_BRANCH)
endif

# docker-tag from git
ifdef TF_VAR_docker_image_tag
	DOCKER_TAG := $(TF_VAR_docker_image_tag)
else ifdef CHANGE_ID
	DOCKER_TAG ?= mr-$(CHANGE_ID)-$(BUILD_NUMBER)
else ifdef GIT_BRANCH
	DOCKER_TAG ?= $(GIT_BRANCH)-$(BUILD_NUMBER)
else
	DOCKER_TAG ?= dev-$(GIT_COMMIT)
endif

REPO_NAME	:= $(shell echo '$(REPO_NAME)' | tr '[:upper:]' '[:lower:]')

CI_REGISTRY_IMAGE ?= $(REPO_NAME)

$(info docker-tagging as [$(CI_REGISTRY_IMAGE):$(DOCKER_TAG)])
$(info )


.PHONY: all
all:


.PHONY: build
build:
	$(info )
	$(info 👷🔨 $(bold)Building$(sgr0) 👷🔨)
	$(info )

	docker build \
		--pull \
		-f Dockerfile \
		-t '$(CI_REGISTRY_IMAGE):$(DOCKER_TAG)' \
		.

.PHONY: test
test:
	$(info )
	$(info no tests)
	$(info )


.PHONY: publish
publish:
	$(info )
	$(info 🐳🚀 $(bold)Publishing: $(CI_REGISTRY_IMAGE):$(DOCKER_TAG)$(sgr0) 🐳🚀)
	$(info )
	docker push '$(CI_REGISTRY_IMAGE):$(DOCKER_TAG)'

ifeq ($(GIT_BRANCH),main)
	$(info )
	$(info 🐳🚀 $(bold)Publishing: $(CI_REGISTRY_IMAGE):latest$(sgr0) 🐳🚀)
	$(info )
	docker tag '$(CI_REGISTRY_IMAGE):$(DOCKER_TAG)' '$(CI_REGISTRY_IMAGE):latest'
	docker push '$(CI_REGISTRY_IMAGE):latest'
endif

