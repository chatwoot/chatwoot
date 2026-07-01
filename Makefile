# Variables
APP_NAME := chatwoot
RAILS_ENV ?= development

# Targets
setup:
	@echo "Checking dependencies..."
	@if command -v brew >/dev/null 2>&1; then \
		echo "Detecting pg_config..."; \
		PG_CONFIG_PATH=$$(find /opt/homebrew -name pg_config 2>/dev/null | head -1 || find /usr/local -name pg_config 2>/dev/null | head -1); \
		if [ -n "$$PG_CONFIG_PATH" ]; then \
			echo "Found pg_config at $$PG_CONFIG_PATH"; \
			bundle config build.pg --with-pg-config=$$PG_CONFIG_PATH; \
		else \
			echo "Warning: pg_config not found. You may need to install libpq: brew install libpq"; \
		fi; \
	fi
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

# Local development helpers (without Docker for app)
local-db-up:
	docker-compose -f docker-compose.local.yml up -d

local-db-down:
	docker-compose -f docker-compose.local.yml down

local-db-logs:
	docker-compose -f docker-compose.local.yml logs -f

local-db-status:
	docker-compose -f docker-compose.local.yml ps

.PHONY: setup db_create db_migrate db_seed db_reset db console server burn docker run force_run force_run_tunnel debug debug_worker local-db-up local-db-down local-db-logs local-db-status
