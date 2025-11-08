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

db_rollback:
	RAILS_ENV=$(RAILS_ENV) bundle exec rails db:rollback

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
	rm -f ./.overmind.sock
	rm -f tmp/pids/*.pid
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

# Local Development with Docker
#
# Docker Setup Pre-requisites:
# Before proceeding, make sure you have the latest version of docker and docker-compose installed.
# Recommended versions:
# - Docker version 25.0.4 or higher
# - Docker Compose version 2.24.7 or higher
#
# Development workflow:
# 1. Clone the repository: git clone https://github.com/chatwoot/chatwoot.git
# 2. Copy .env.example to .env and update Redis and Postgres passwords
# 3. Build the images using the commands below
# 4. Prepare the database using dev-prepare
# 5. Start the application using dev-up or dev-start
# 6. Access the app at http://localhost:3000
#    - Default login: john@acme.inc / Password1!
# 7. Access Mailhog at http://localhost:8025

# Copy environment file
dev-env:
	cp -n .env.example .env
	@echo "Please update Redis and Postgres passwords in .env file"
	@echo "Also update docker-compose.yaml with the same Postgres password if needed"

# Build the base image first, then build all services
dev-setup:
	docker compose build base
	docker compose build

# Start the application in development mode (interactive)
dev-start:
	docker compose up

# Start the application in detached mode
dev-up:
	docker compose up -d

# Stop the application
dev-down:
	docker compose down

# Prepare the database (reset and setup)
dev-prepare:
	docker compose run --rm rails bundle exec rails db:chatwoot_prepare

# Execute database migrations
dev-migrate:
	docker compose run --rm rails bundle exec rails db:migrate

# Full setup: build, prepare DB, and start
dev-init: dev-setup dev-prepare dev-up
	@echo "Application is now running at http://localhost:3000"
	@echo "Login with: john@acme.inc / Password1!"
	@echo "Mailhog is available at http://localhost:8025"

# View logs from all containers or a specific service
dev-logs:
	@if [ -z "$(service)" ]; then \
		docker compose logs -f; \
	else \
		docker compose logs -f $(service); \
	fi

# Access Rails console in the running container
dev-console:
	docker compose run --rm rails bundle exec rails console

# Production 
# db_prepare:
# 	docker compose run --rm rails bundle exec rails db:chatwoot_prepare

.PHONY: setup db_create db_migrate db_rollback db_seed db_reset db console server burn docker run force_run debug debug_worker dev-setup dev-up dev-down dev-migrate dev-init dev-logs dev-console force_run_tunnel
