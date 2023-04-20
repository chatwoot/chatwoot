# Variables
APP_NAME := chatwoot
RAILS_ENV ?= development

# Targets
setup:
	gem install bundler
	bundle install
	yarn install

db_create:
	rails db:create

db_migrate:
	rails db:migrate RAILS_ENV=$(RAILS_ENV)

db_seed:
	rails db:seed RAILS_ENV=$(RAILS_ENV)

db_prepare:
	RAILS_ENV=$(RAILS_ENV) bundle exec rails db:chatwoot_prepare

console:
	RAILS_ENV=$(RAILS_ENV) bundle exec rails console

server:
	RAILS_ENV=$(RAILS_ENV) bundle exec rails server -b 0.0.0.0 -p 3000

burn:
	bundle && yarn

run:
	overmind start -f Procfile.dev

docker: 
	docker build -t $(APP_NAME) -f ./docker/Dockerfile .

.PHONY: setup db_create db_migrate db_seed db_prepare console server burn docker run
