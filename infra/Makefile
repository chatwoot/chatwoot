# 💥
# 💥 FILE WILL BE OVERWRITTEN
# 💥

SHELL := bash

TF_UPGRADE_BRANCH ?= main
TF_UPGRADE_TMP    ?= tmp
TF_PARALLELISM    ?= 10

ifdef CI_ENVIRONMENT_NAME
	ENV := $(CI_ENVIRONMENT_NAME)
endif
ENV ?= dev
REPO ?= $(shell git -C '$(CURDIR)/../' remote get-url origin | cut -d':' -f2 | sed 's/\.git$$//')
SYSTEM ?= $(notdir $(REPO))

ifdef TENANT
	WORKSPACE := $(TENANT)-$(ENV)
	TFENV_FILE := $(CURDIR)/env/$(TENANT)/$(ENV).tfvars
else
	WORKSPACE := $(ENV)
	TFENV_FILE := $(CURDIR)/env/$(ENV).tfvars
endif

# EFS: stale NFS file handle
# ifeq ($(CI),true)
#	export TF_PLUGIN_CACHE_DIR=/cache/terraform
# endif


export TF_DATA_DIR=$(CURDIR)/.terraform_$(WORKSPACE)


.PHONY: all
all:


.PHONY: create
create:
	mkdir -p \
		env

# create _backend.tf from template
ifeq (,$(wildcard _backend.tf))
ifndef SYSTEM
	$(error SYSTEM required)
endif
ifndef REPO
	$(error REPO required)
endif
ifndef ENV
	$(error ENV required)
endif
ifndef OWNER
	$(error OWNER required)
endif
ifndef TYPE
	$(error TYPE required)
endif
	sed 's#SYSTEM#$(SYSTEM)#g; s#OWNER#$(OWNER)#g; s#REPO#$(REPO)#g' '$(CURDIR)/templates/_backend.tf' > '$(CURDIR)/_backend.tf'
endif

# make sure env-tfvars exist
ifdef TENANT
	mkdir env/$(TENANT)
endif
	touch '$(TFENV_FILE)'

# cleanups
ifneq (,$(findstring /infra,$(PWD)))
	rm -rf .git .gitlab-ci.yml README.md templates
endif


.PHONY: upgrade
upgrade:
ifeq ($(TF_UPGRADE_TMP),)
	exit 1
endif
	rm -rf $(TF_UPGRADE_TMP)

	git clone --depth 1 --single-branch -b '$(TF_UPGRADE_BRANCH)' git@gitlab.digitaltolk.net:dtolk/dope/terraboot.git '$(TF_UPGRADE_TMP)'

	cp -f '$(TF_UPGRADE_TMP)'/*.tf '$(TF_UPGRADE_TMP)'/{Makefile,.gitignore,.terraform.lock.hcl,.terraform-version,.editorconfig} '$(CURDIR)'/
	rm -rf '$(TF_UPGRADE_TMP)'

	terraform init -upgrade


.PHONY: update
update: check-env
	terraform get -update


.PHONY: lock
lock:
	terraform init -upgrade
	rm '$(CURDIR)'/.terraform.lock.hcl
	terraform providers lock \
		-platform=darwin_arm64 \
		-platform=darwin_amd64 \
		-platform=linux_amd64 \
		-platform=linux_arm64


.PHONY: init
init: check-env
ifeq ($(CI),true)
	printf 'provider_installation {\n  filesystem_mirror {\n    path    = "/cache/terraform/providers"\n    include = ["*/*/*"]\n  }\n}\n' | tee ~/.terraformrc
endif
	terraform init
	terraform get -update

	if ! terraform workspace select '$(WORKSPACE)' 2> /dev/null; then \
		terraform workspace new '$(WORKSPACE)' ;\
	fi


.PHONY: plan
plan: check-env
	terraform plan  \
		-parallelism=$(TF_PARALLELISM) \
		-lock-timeout=600s \
		-var-file='$(TFENV_FILE)' \
		-out '$(ENV).plan'


.PHONY: apply
apply: check-env
	terraform apply \
		-parallelism=$(TF_PARALLELISM) \
		-lock-timeout=600s \
		'$(ENV).plan'


.PHONY: import
import: check-env
	terraform import \
		-var-file='$(TFENV_FILE)' \
		-lock-timeout=600s '$(ADDR)' '$(ID)'


.PHONY: state-rm
state-rm: check-env
	terraform state rm -lock-timeout=600s '$(ADDR)'


.PHONY: state-mv
state-mv: check-env
	terraform state mv -lock-timeout=600s '$(SRC)' '$(DEST)'


.PHONY: unlock
unlock: check-env
	terraform force-unlock '$(LOCK_ID)'


.PHONY: console
console: check-env
	terraform console -var-file='$(TFENV_FILE)'


.PHONY: taint
taint: check-env
	terraform taint -lock-timeout=600s '$(ADDR)'


.PHONY: fmt
fmt:
	terraform fmt

.PHONY: vfmt
vfmt:
	terraform validate && terraform fmt

.PHONY: providers
providers:
	terraform providers


.PHONY: destroy
destroy: check-env
	terraform destroy \
		-parallelism=$(TF_PARALLELISM) \
		-var-file='$(TFENV_FILE)' \
		-lock-timeout=600s


.PHONY: check-env
check-env:
ifndef ENV
	$(error ENV is undefined)
endif
ifeq ($(wildcard $(TFENV_FILE)),)
	$(error ENV does not exist)
endif
