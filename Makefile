.PHONY: help sync-upstream build-image push-image docker-setup docker-reset docker-logs docker-stop

# Variables
UPSTREAM_REPO = https://github.com/chatwoot/chatwoot.git
UPSTREAM_BRANCH = develop
IMAGE_NAME = chatwoot-custom
IMAGE_TAG = latest
REGISTRY_URL = # Set your registry URL here (e.g., registry.example.com)

help: ## Show this help message
	@echo "Chatwoot Fork Management Makefile"
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

##@ Repository Sync

sync-upstream: ## Sync fork with upstream Chatwoot repository
	@echo "📡 Syncing with upstream Chatwoot..."
	@git remote -v | grep -q upstream || git remote add upstream $(UPSTREAM_REPO)
	@git fetch upstream
	@echo "✓ Fetched upstream changes"
	@git checkout $(UPSTREAM_BRANCH)
	@git merge upstream/$(UPSTREAM_BRANCH)
	@echo "✅ Merged upstream/$(UPSTREAM_BRANCH) into $(UPSTREAM_BRANCH)"
	@echo ""
	@echo "💡 Next steps:"
	@echo "   1. Resolve any conflicts if needed"
	@echo "   2. Test the changes: make docker-reset"
	@echo "   3. Push to your fork: git push origin $(UPSTREAM_BRANCH)"

check-upstream: ## Check for upstream changes
	@echo "🔍 Checking for upstream changes..."
	@git remote -v | grep -q upstream || git remote add upstream $(UPSTREAM_REPO)
	@git fetch upstream
	@echo ""
	@git log HEAD..upstream/$(UPSTREAM_BRANCH) --oneline --no-merges | head -10
	@echo ""
	@echo "💡 Run 'make sync-upstream' to merge these changes"

##@ Docker Development

docker-setup: ## Initial setup - creates .env and starts all services
	@echo "🐳 Setting up Docker environment..."
	@./setup.sh

docker-reset: ## Reset everything - stops containers, removes volumes, and starts fresh
	@echo "🔄 Resetting Docker environment..."
	@./quick-reset.sh

docker-up: ## Start all Docker services
	@echo "🚀 Starting Docker services..."
	@docker-compose up -d
	@echo "✅ Services started"
	@echo ""
	@echo "URLs:"
	@echo "  Web App:  http://localhost:3000"
	@echo "  Vite Dev: http://localhost:3036"
	@echo "  MailHog:  http://localhost:8025"

docker-down: ## Stop all Docker services
	@echo "🛑 Stopping Docker services..."
	@docker-compose down
	@echo "✅ Services stopped"

docker-stop: docker-down ## Alias for docker-down

docker-logs: ## Show logs from all services
	@docker-compose logs -f

docker-logs-rails: ## Show Rails logs
	@docker-compose logs -f rails

docker-console: ## Open Rails console
	@docker-compose exec rails bundle exec rails console

docker-bash: ## Open bash shell in Rails container
	@docker-compose exec rails bash

docker-migrate: ## Run database migrations
	@echo "🗄️  Running migrations..."
	@docker-compose exec rails bundle exec rails db:migrate
	@echo "✅ Migrations complete"

docker-rollback: ## Rollback last migration
	@echo "↩️  Rolling back last migration..."
	@docker-compose exec rails bundle exec rails db:rollback
	@echo "✅ Rollback complete"

docker-seed: ## Seed database with test data
	@echo "🌱 Seeding database..."
	@docker-compose exec rails bundle exec rails db:seed
	@echo "✅ Database seeded"

##@ Testing

test: ## Run all RSpec tests
	@echo "🧪 Running tests..."
	@docker-compose exec rails bundle exec rspec

test-participating: ## Run participating_only feature tests
	@echo "🧪 Running participating_only tests..."
	@docker-compose exec rails bundle exec rspec spec/services/conversations/permission_filter_service_spec.rb
	@docker-compose exec rails bundle exec rspec spec/policies/conversation_policy_spec.rb
	@docker-compose exec rails bundle exec rspec spec/models/account_user_spec.rb

lint-ruby: ## Run RuboCop
	@echo "🔍 Linting Ruby code..."
	@docker-compose exec rails bundle exec rubocop -a

lint-js: ## Run ESLint
	@echo "🔍 Linting JavaScript/Vue code..."
	@docker-compose exec rails pnpm eslint:fix

##@ Production Docker Image

build-image: ## Build production Docker image for Portainer
	@echo "🏗️  Building production Docker image..."
	@docker build \
		-f docker/Dockerfile \
		-t $(IMAGE_NAME):$(IMAGE_TAG) \
		--build-arg RAILS_ENV=production \
		--build-arg NODE_ENV=production \
		--build-arg BUNDLE_WITHOUT=development:test \
		.
	@echo "✅ Image built: $(IMAGE_NAME):$(IMAGE_TAG)"
	@echo ""
	@echo "💡 Next steps:"
	@echo "   1. Test the image locally: make run-prod-image"
	@echo "   2. Tag for registry: make tag-image"
	@echo "   3. Push to registry: make push-image"

tag-image: ## Tag image for registry
	@if [ -z "$(REGISTRY_URL)" ]; then \
		echo "❌ Error: REGISTRY_URL not set"; \
		echo "   Set it in Makefile or run: make tag-image REGISTRY_URL=registry.example.com"; \
		exit 1; \
	fi
	@echo "🏷️  Tagging image for registry..."
	@docker tag $(IMAGE_NAME):$(IMAGE_TAG) $(REGISTRY_URL)/$(IMAGE_NAME):$(IMAGE_TAG)
	@docker tag $(IMAGE_NAME):$(IMAGE_TAG) $(REGISTRY_URL)/$(IMAGE_NAME):latest
	@echo "✅ Images tagged:"
	@echo "   $(REGISTRY_URL)/$(IMAGE_NAME):$(IMAGE_TAG)"
	@echo "   $(REGISTRY_URL)/$(IMAGE_NAME):latest"

push-image: ## Push image to registry
	@if [ -z "$(REGISTRY_URL)" ]; then \
		echo "❌ Error: REGISTRY_URL not set"; \
		echo "   Set it in Makefile or run: make push-image REGISTRY_URL=registry.example.com"; \
		exit 1; \
	fi
	@echo "📤 Pushing image to registry..."
	@docker push $(REGISTRY_URL)/$(IMAGE_NAME):$(IMAGE_TAG)
	@docker push $(REGISTRY_URL)/$(IMAGE_NAME):latest
	@echo "✅ Images pushed to $(REGISTRY_URL)"

##@ Cleanup

clean-docker: ## Remove all containers, images, and volumes
	@echo "🧹 Cleaning up Docker resources..."
	@docker-compose down -v
	@docker rmi chatwoot:development chatwoot-rails:development chatwoot-vite:development 2>/dev/null || true
	@echo "✅ Docker resources cleaned"

status: ## Show status of all Docker services
	@docker-compose ps

health: ## Check health of services
	@echo "🏥 Checking service health..."
	@echo ""
	@echo "PostgreSQL:"
	@docker-compose exec postgres psql -U postgres -c "SELECT 1" > /dev/null 2>&1 && echo "  ✅ OK" || echo "  ❌ FAILED"
	@echo ""
	@echo "Redis:"
	@docker-compose exec redis redis-cli ping > /dev/null 2>&1 && echo "  ✅ OK" || echo "  ❌ FAILED"
	@echo ""
	@echo "Rails:"
	@curl -s -o /dev/null -w "  Status: %{http_code}\n" http://localhost:3000

version: ## Show current version info
	@echo "Chatwoot Fork Version Information"
	@echo "================================="
	@echo ""
	@echo "Current branch:"
	@git branch --show-current
	@echo ""
	@echo "Last commit:"
	@git log -1 --oneline

