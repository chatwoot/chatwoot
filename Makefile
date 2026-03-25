# Variables
APP_NAME := chatwoot
RAILS_ENV ?= development

# Targets
setup:
	gem install bundler
	bundle install
	pnpm install

db_create:
	RAILS_ENV=$(RAILS_ENV) bundle exec rails db:create

db_migrate:
	RAILS_ENV=$(RAILS_ENV) bundle exec rails db:migrate

db_seed:
	RAILS_ENV=$(RAILS_ENV) bundle exec rails db:seed

db_reset:
	RAILS_ENV=$(RAILS_ENV) bundle exec rails db:reset

db:
	RAILS_ENV=$(RAILS_ENV) bundle exec rails db:chatwoot_prepare

console:
	RAILS_ENV=$(RAILS_ENV) bundle exec rails console

server:
	RAILS_ENV=$(RAILS_ENV) bundle exec rails server -b 0.0.0.0 -p 3000

burn:
	bundle && pnpm install

run:
	@if [ -f ./.overmind.sock ]; then \
		echo "Overmind is already running. Use 'make force_run' to start a new instance."; \
	else \
		overmind start -f Procfile.dev; \
	fi

force_run:
	@echo "Cleaning up Overmind processes..."
	@lsof -ti:3036 2>/dev/null | xargs kill -9 2>/dev/null || true
	@lsof -ti:3000 2>/dev/null | xargs kill -9 2>/dev/null || true
	@rm -f ./.overmind.sock
	@rm -f tmp/pids/*.pid
	@echo "Cleanup complete"
	overmind start -f Procfile.dev

# Development convenience targets
.PHONY: dev setup-local test test-js test-ruby lint lint-js lint-ruby help

dev:
	pnpm dev

setup-local:
	@bash setup-dev.sh

test: test-ruby test-js

test-ruby:
	bundle exec rspec

test-js:
	pnpm test

lint: lint-ruby lint-js

lint-ruby:
	bundle exec rubocop -a

lint-js:
	pnpm eslint:fix

help:
	@echo "Available targets:"
	@echo "  make setup         - Install dependencies (gems & packages)"
	@echo "  make setup-local   - Complete local development setup (recommended)"
	@echo "  make db            - Prepare database"
	@echo "  make db_create     - Create database"
	@echo "  make db_migrate    - Run migrations"
	@echo "  make db_seed       - Seed database with test data"
	@echo "  make db_reset      - Reset database (careful!)"
	@echo "  make dev           - Start development servers (pnpm dev)"
	@echo "  make run           - Start with Overmind (Procfile.dev)"
	@echo "  make force_run     - Force start Overmind (cleanup stale processes)"
	@echo "  make console       - Open Rails console"
	@echo "  make server        - Start Rails server only"
	@echo "  make test          - Run all tests (Ruby + JavaScript)"
	@echo "  make test-ruby     - Run RSpec tests"
	@echo "  make test-js       - Run JavaScript tests"
	@echo "  make lint          - Run all linters with auto-fix"
	@echo "  make lint-ruby     - Run RuboCop with auto-fix"
	@echo "  make lint-js       - Run ESLint with auto-fix"
	@echo "  make help          - Show this help message"

force_run_tunnel:
	lsof -ti:3000 | xargs kill -9 2>/dev/null || true
	rm -f ./.overmind.sock
	rm -f tmp/pids/*.pid
	overmind start -f Procfile.tunnel

debug:
	overmind connect backend

debug_worker:
	overmind connect worker

docker:
	docker build -t $(APP_NAME) -f ./docker/Dockerfile .

.PHONY: setup db_create db_migrate db_seed db_reset db console server burn docker run force_run force_run_tunnel debug debug_worker
