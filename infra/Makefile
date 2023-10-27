# 💥
# 💥 FILE WILL BE OVERWRITTEN
# 💥

SHELL := bash

TF_UPGRADE_BRANCH ?= main
TF_UPGRADE_TMP    ?= tmp

ifdef CI_ENVIRONMENT_NAME
	ENV := $(CI_ENVIRONMENT_NAME)
endif
ENV ?= dev
REPO ?= $(shell git -C '$(CURDIR)/../' remote get-url origin | cut -d':' -f2 | sed 's/\.git$$//')
SYSTEM ?= $(notdir $(REPO))


export TF_DATA_DIR=.terraform_$(ENV)


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
	sed 's#SYSTEM#$(SYSTEM)#g; s#OWNER#$(OWNER)#g; s#REPO#$(REPO)#g' '$(CURDIR)/templates/_backend.tf' > '$(CURDIR)/_backend.tf'
endif

# make sure env-tfvars exist
	touch 'env/$(ENV).tfvars'

# cleanups
ifneq (,$(findstring /infra,$(PWD)))
	rm -rf .git README.md templates
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
	terraform init
	terraform get -update

	if ! terraform workspace select '$(ENV)' 2> /dev/null; then \
		terraform workspace new '$(ENV)' ;\
	fi


.PHONY: plan
plan: check-env
	terraform plan  \
		-lock-timeout=600s \
		-var-file='env/$(ENV).tfvars' \
		-out '$(ENV).plan'


.PHONY: apply
apply: check-env
	terraform apply \
		-lock-timeout=600s \
		'$(ENV).plan'


.PHONY: import
import: check-env
	terraform import \
		-var-file='env/$(ENV).tfvars' \
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


.PHONY: taint
taint: check-env
	terraform taint -lock-timeout=600s '$(ADDR)'


.PHONY: fmt
fmt:
	terraform fmt


.PHONY: destroy
destroy: check-env
	terraform destroy \
		-var-file='env/$(ENV).tfvars' \
		-lock-timeout=600s


.PHONY: check-env
check-env:
ifndef ENV
	$(error ENV is undefined)
endif
ifeq ($(wildcard $(CURDIR)/env/$(ENV).tfvars),)
	$(error ENV does not exist)
endif
