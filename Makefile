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

# Dev images (rails + vite) — built straight from docker/Dockerfile, no manual
# base-image pre-build needed. `docker compose up` then just uses them.
build-dev:
	docker compose build

# Start the dev stack WITHOUT rebuilding the images. In dev, your code is
# bind-mounted (./:/app) so editing Ruby/Vue files does NOT require a rebuild —
# use this the vast majority of the time. Only `build-dev`/`build` when you
# change Gemfile / package.json / the Dockerfile itself.
up:
	docker compose up -d

# Full rebuild + start (only when deps/Dockerfile changed).
build-up:
	docker compose up -d --build

# Recreate containers without rebuilding images (picks up compose/env changes).
restart:
	docker compose up -d --force-recreate

# Production image, pushed to ghcr.io/kira-id (linux/amd64).
# Requires: docker buildx + `docker login ghcr.io`.
# (Uses BuildKit cache mounts — set DOCKER_BUILDKIT=1 if not default, which is
# the case on current Docker Desktop for Windows.)
build-prod:
	docker buildx build --platform linux/amd64 --tag ghcr.io/kira-id/chatwoot:latest --push -f docker/Dockerfile .

.PHONY: setup db_create db_migrate db_seed db_reset db console server burn docker build-dev build-prod run force_run force_run_tunnel debug debug_worker up build-up restart
