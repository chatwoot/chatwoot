# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Chatwoot is an open-source customer support platform built with Ruby on Rails (backend) and Vue 3 (frontend). It provides omnichannel support, live chat, help center, and AI-powered customer support features.

**Stack:**
- Backend: Rails 7.0, Ruby 3.3.3
- Frontend: Vue 3, Vite, TailwindCSS
- Database: PostgreSQL with pgvector for AI features
- Background Jobs: Sidekiq
- Real-time: ActionCable (WebSocket)
- Package Manager: pnpm 10.x for JavaScript, Bundler for Ruby

## Common Commands

### Development Setup
```bash
make setup                    # Install dependencies (bundle + pnpm)
make burn                     # Quick reinstall of dependencies
make db                       # Run db:chatwoot_prepare (create, migrate, seed)
make run                      # Start development server (overmind)
make force_run                # Force restart overmind
make debug                    # Connect to Rails console in overmind
make debug_worker             # Connect to Sidekiq worker in overmind
```

### Running the Application
```bash
# Using overmind (recommended for development)
overmind start -f Procfile.dev

# Using foreman
foreman start -f Procfile.dev

# Start processes individually
bin/rails s -p 3000          # Rails server
bin/vite dev                 # Vite dev server
bundle exec sidekiq -C config/sidekiq.yml  # Background workers
```

The Procfile.dev defines three processes: `backend` (Rails), `worker` (Sidekiq), `vite` (frontend dev server).

### Testing

**Ruby/Rails Tests (RSpec):**
```bash
bundle exec rspec                           # Run all specs
bundle exec rspec spec/models               # Run model specs
bundle exec rspec spec/path/to/file_spec.rb # Run single file
bundle exec rspec spec/path/to/file_spec.rb:42  # Run single example at line 42
```

**JavaScript Tests (Vitest):**
```bash
pnpm test                    # Run all tests (no watch)
pnpm test:watch              # Run tests in watch mode
pnpm test:coverage           # Run tests with coverage
```

### Linting & Code Quality
```bash
# Ruby
bundle exec rubocop                    # Run rubocop
bundle exec rubocop -a                 # Auto-fix issues
pnpm ruby:prettier                     # Format Ruby code

# JavaScript
pnpm eslint                            # Run eslint
pnpm eslint:fix                        # Auto-fix JS/Vue issues
```

### Database
```bash
bundle exec rails db:migrate           # Run migrations
bundle exec rails db:rollback          # Rollback last migration
bundle exec rails db:reset             # Drop, create, migrate, seed
bundle exec rails db:chatwoot_prepare  # Custom setup task
```

### Building
```bash
bin/vite build                         # Build frontend assets
pnpm build:sdk                         # Build SDK separately (BUILD_MODE=library)
```

## Architecture

### Backend Architecture

**Directory Structure:**
- `app/models/` - ActiveRecord models (~91 models)
- `app/controllers/` - Controllers (nested under `api/v1` for API endpoints)
- `app/services/` - Service objects for business logic
- `app/jobs/` - ActiveJob background jobs
- `app/workers/` - Sidekiq workers (legacy, prefer jobs)
- `app/listeners/` - Event listeners (Wisper pattern)
- `app/builders/` - Response builders
- `app/finders/` - Query objects
- `app/policies/` - Pundit authorization policies
- `app/dispatchers/` - Event dispatchers
- `lib/` - Shared utilities and custom libraries
- `enterprise/` - Enterprise features (separate namespace)

**Key Patterns:**

1. **Event-Driven Architecture (Wisper):**
   - Models broadcast events using `Wisper.publish`
   - Listeners subscribe to events (e.g., `NotificationListener`, `WebhookListener`)
   - Events defined in `lib/events/` (inherit from `Events::Base`)
   - Listeners in `app/listeners/` (inherit from `BaseListener`)

2. **Service Objects:**
   - Business logic extracted into service objects in `app/services/`
   - Example: `Conversations::CreateService`, `Messages::MessageBuilder`

3. **Finder Pattern:**
   - Query logic in `app/finders/` (e.g., `MessageFinder`, `ConversationFinder`)

4. **Background Jobs:**
   - Prefer ActiveJob (`app/jobs/`) over raw Sidekiq workers
   - Sidekiq configured in `config/sidekiq.yml`
   - Cron jobs managed via `sidekiq-cron`

5. **Authorization:**
   - Pundit policies in `app/policies/`

6. **Real-time Updates:**
   - ActionCable channels in `app/channels/`
   - `RoomChannel` handles WebSocket subscriptions
   - Broadcasts via `ActionCableBroadcastJob`

**Model Concerns:**
Common concerns in `app/models/concerns/`:
- `Avatarable` - Avatar management
- `Assignable` - Assignment logic
- `Channelable` - Channel integration
- `AccessTokenable` - Token generation
- Plus many others for shared behavior

### Frontend Architecture

**Directory Structure:**
- `app/javascript/dashboard/` - Main dashboard application (Vue 3)
- `app/javascript/widget/` - Customer-facing chat widget
- `app/javascript/portal/` - Help center portal
- `app/javascript/sdk/` - JavaScript SDK
- `app/javascript/v3/` - New Vue 3 components
- `app/javascript/design-system/` - Shared design system
- `app/javascript/shared/` - Shared utilities and components
- `app/javascript/entrypoints/` - Vite entry points

**Frontend Stack:**
- Vue 3 with Composition API
- Vuex for state management
- Vue Router for routing
- Vite as build tool (via vite_rails gem)
- TailwindCSS for styling
- Vitest for testing

**Key Frontend Files:**
- `vite.config.ts` - Vite configuration (supports library mode for SDK)
- `tailwind.config.js` - TailwindCSS configuration
- `vitest.setup.js` - Vitest test setup
- `histoire.config.ts` - Component story tool (Histoire)

### Enterprise Features

Enterprise-specific code lives in `enterprise/`:
- `enterprise/app/` - Enterprise models, controllers, services
- `enterprise/lib/` - Enterprise libraries
- `enterprise/listeners/` - Enterprise event listeners
- `enterprise/config/` - Enterprise configuration (premium features, installation config)

These paths are added to Rails eager_load_paths in `config/application.rb`.

## Database & Migrations

- PostgreSQL is the primary database
- Uses `pgvector` extension for AI/ML features (vector similarity search)
- Uses `neighbor` gem for cosine similarity
- Database triggers managed via `hairtrigger` gem
- Full-text search via `pg_search` gem

## Testing Guidelines

**RSpec Setup:**
- Configured in `.rspec` and `spec/spec_helper.rb`
- Uses SimpleCov for coverage
- Uses WebMock for HTTP stubbing
- Factory pattern with `factory_bot_rails`
- Test profiling available via `test-prof` gem

**Vitest Setup:**
- Tests colocated with components or in `spec/` equivalent
- Uses `@vue/test-utils` for component testing
- Uses `fake-indexeddb` for IndexedDB mocking
- Timezone set to UTC for consistency

## Integrations & Channels

Chatwoot supports multiple channels:
- Email (IMAP mailboxes in `app/mailboxes/`)
- Facebook Messenger (`facebook-messenger` gem)
- Twitter (`twitty` gem)
- Twilio (`twilio-ruby` gem)
- Line (`line-bot-api` gem)
- Slack (`slack-ruby-client` gem)
- WhatsApp (via Twilio)
- And more...

Integrations:
- Dialogflow for chatbots (`google-cloud-dialogflow-v2`)
- Google Translate (`google-cloud-translate-v3`)
- Stripe for billing
- Shopify (`shopify_api`)
- OpenAI (`ruby-openai`) for AI features

## Environment Variables

Configuration is managed via:
- `.env` files (loaded by `dotenv-rails`)
- `.env.example` contains template
- `config/app.yml` for custom Chatwoot config (accessed via `Chatwoot.config`)

## Git Workflow

- Branching model: git-flow
- Base branch: `develop` (NOT `master`)
- Stable releases: `master` branch

## Performance & Monitoring

**Performance Page:**
- `/perf` - Performance monitoring dashboard
- `/perf/ping` - Server health check
- `/perf/database` - Database diagnostics
- `/perf/redis` - Redis diagnostics

## Important Notes

1. **Vite Build Modes:**
   - Regular build: `bin/vite build` (excludes SDK)
   - SDK build: `BUILD_MODE=library bin/vite build` (SDK only in UMD format)
   - SDK has special handling due to needing `inlineDynamicImports`

2. **Autoloading:**
   - Rails autoloads `lib/` and all `enterprise/` paths
   - 43 initializers in `config/initializers/`

3. **Asset Management:**
   - ActiveStorage for file uploads
   - Supports AWS S3, Azure Blob, Google Cloud Storage
   - `image_processing` for image transformations

4. **Security:**
   - Devise for authentication
   - `devise_token_auth` for API tokens
   - JWT for token management
   - Pundit for authorization
   - `rack-attack` for rate limiting

5. **Geocoding:**
   - Uses `geocoder` gem with MaxMind DB (`maxminddb`)

6. **Markdown & Templating:**
   - `commonmarker` for Markdown to HTML
   - `liquid` for template parsing
   - `reverse_markdown` for HTML to Markdown

7. **Working Hours:**
   - `working_hours` gem for business hours calculations

8. **Deployment:**
   - Docker support (multiple Dockerfiles for different environments)
   - Kubernetes configs in `kubernetes/`
   - Heroku support via `app.json`
   - `judoscale` for autoscaling
