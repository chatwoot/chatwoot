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
AWS_ECR_ACCOUNT	?= 178432136258
AWS_ECR_REGION	?= eu-north-1


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

DOCKER_REPO ?= $(AWS_ECR_ACCOUNT).dkr.ecr.$(AWS_ECR_REGION).amazonaws.com/$(REPO_NAME)

$(info docker-tagging as [$(DOCKER_REPO):$(DOCKER_TAG)])
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
		-t '$(DOCKER_REPO):$(DOCKER_TAG)' \
		.

.PHONY: pull
pull:
	$(info )
	$(info 👷🔨 $(bold)Pulling$(sgr0) 👷🔨)
	$(info )

	docker pull '$(DOCKER_REPO):$(DOCKER_TAG)'

.PHONY: test-setup
test-setup:
	$(info )
	$(info 🔨 $(bold)Setting up test environment$(sgr0) 🔨)
	$(info )
	apk update && apk add --no-cache \
		openssl \
		tar \
		build-base \
		tzdata \
		postgresql-dev \
		postgresql-client \
		nodejs-current \
		yarn \
		git \
		glib \
		gobject-introspection \
		gobject-introspection-dev \
		libarrow \
		libarrow_acero \
		libparquet \
		&& apk add --no-cache --virtual=.build-dependencies\
		apache-arrow-dev \
		glib-dev \
		meson \
		pkgconf \
		samurai \
		libc6-compat

	wget "https://www.apache.org/dyn/closer.lua?action=download&filename=arrow/arrow-16.1.0/apache-arrow-16.1.0.tar.gz" \
		&& tar xf apache-arrow-16.1.0.tar.gz && \
		meson setup \
			apache-arrow-16.1.0/c_glib.build \
			apache-arrow-16.1.0/c_glib \
			--prefix=/usr \
			--buildtype=minsize
	meson install -C apache-arrow-16.1.0/c_glib.build
	rm -rf apache-arrow-16.1.0 \
		&& mkdir -p /var/app \
		&& gem install bundler
	bundle install
	apk add --no-cache nodejs npm yarn chromium
	npm install --global yarn
	yarn install --check-files
	bundle exec rails webpacker:compile
	bundle exec rake db:create
	bundle exec rake db:schema:load

.PHONY: test_spec_1
test_spec_1:
	$(info )
	$(info Running RSpec tests...)
	$(info )
	RAILS_ENV=test bundle exec rspec spec/builders --profile=10 --format documentation

.PHONY: test_spec_2
test_spec_2:
	$(info )
	$(info Running RSpec tests...)
	$(info )
	RAILS_ENV=test bundle exec rspec --exclude-pattern "spec/builders/**/*_spec.rb" --profile=10 --format documentation

.PHONY: test_frontend
test_frontend:
	$(info )
	$(info Running frontend tests...)
	$(info )
	yarn test --coverage

.PHONY: publish
publish: docker-login
	$(info )
	$(info 🐳🚀 $(bold)Publishing: $(DOCKER_REPO):$(DOCKER_TAG)$(sgr0) 🐳🚀)
	$(info )
	docker push '$(DOCKER_REPO):$(DOCKER_TAG)'

ifeq ($(GIT_BRANCH),main)
	$(info )
	$(info 🐳🚀 $(bold)Publishing: $(DOCKER_REPO):latest$(sgr0) 🐳🚀)
	$(info )
	docker tag '$(DOCKER_REPO):$(DOCKER_TAG)' '$(DOCKER_REPO):latest'
	docker push '$(DOCKER_REPO):latest'
endif


.PHONY: docker-login
docker-login:
	$(call ecr_login)


define ecr_login
	@if ! timeout --preserve-status --signal=KILL 3 docker login '$(AWS_ECR_ACCOUNT).dkr.ecr.$(AWS_ECR_REGION).amazonaws.com' &> /dev/null; then \
		echo 'logging into $(AWS_ECR_ACCOUNT).dkr.ecr.$(AWS_ECR_REGION).amazonaws.com...' ;\
		aws --profile "dt-infra" ecr get-login-password --region '$(AWS_ECR_REGION)' | \
		docker login \
			--username AWS \
			--password-stdin '$(AWS_ECR_ACCOUNT).dkr.ecr.$(AWS_ECR_REGION).amazonaws.com' ;\
	fi
endef
