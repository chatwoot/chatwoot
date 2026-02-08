# Project Structure & Organization

## Rails Application Structure

### Core Application (`app/`)
- **controllers/** - API endpoints and web controllers, organized by namespace (api/v1/, webhooks/, etc.)
- **models/** - ActiveRecord models with concerns for shared behavior
- **services/** - Business logic layer, organized by domain (conversations/, messages/, integrations/)
- **jobs/** - Background job classes using Sidekiq
- **workers/** - Specialized worker classes for async processing
- **listeners/** - Event-driven listeners using Wisper pub/sub pattern
- **policies/** - Authorization logic using Pundit
- **builders/** - Object construction and complex initialization logic
- **presenters/** - Data formatting and view logic
- **validators/** - Custom validation classes
- **dispatchers/** - Event dispatching and routing logic

### Frontend (`app/javascript/`)
- **dashboard/** - Main admin/agent interface (Vue.js components)
- **widget/** - Customer-facing chat widget
- **portal/** - Help center and knowledge base frontend
- **survey/** - Customer satisfaction survey components
- **v3/** - Next-generation UI components
- **shared/** - Reusable components and utilities
- **entrypoints/** - Vite entry points for different applications

### Custom Libraries (`lib/`)
- **integrations/** - Third-party service integrations (dialogflow/, slack/, socialwise/, etc.)
- **webhooks/** - Webhook handling and processing
- **tasks/** - Custom Rake tasks
- **redis/** - Redis utilities and configuration
- **events/** - Event system definitions

### Configuration (`config/`)
- **environments/** - Environment-specific settings
- **initializers/** - Application initialization code
- **locales/** - Internationalization files
- **routes.rb** - URL routing configuration

## Key Architectural Patterns

### Service Objects
Business logic is encapsulated in service classes under `app/services/`, organized by domain:
```
app/services/
├── conversations/
├── messages/
├── integrations/
└── [domain]/
```

### Event-Driven Architecture
Uses Wisper for pub/sub pattern:
- **Listeners** (`app/listeners/`) - Subscribe to domain events
- **Events** (`lib/events/`) - Event definitions and types
- **Dispatchers** (`app/dispatchers/`) - Event routing logic

### Integration Pattern
External integrations follow a consistent structure in `lib/integrations/`:
```
lib/integrations/[service]/
├── processor_service.rb     # Main processing logic
├── response_processor.rb    # Response handling
└── [specific_handlers].rb   # Specialized processors
```

### Channel Architecture
Communication channels are organized under:
- **Models**: `app/models/channel/` - Channel-specific models
- **Controllers**: `app/controllers/[channel]/` - Webhook endpoints
- **Services**: `app/services/[channel]/` - Channel business logic

## Naming Conventions

### Ruby/Rails
- **Classes**: PascalCase (`MessageProcessor`)
- **Files**: snake_case (`message_processor.rb`)
- **Methods**: snake_case (`process_message`)
- **Constants**: SCREAMING_SNAKE_CASE (`MAX_MESSAGE_LENGTH`)

### JavaScript/Vue
- **Components**: PascalCase (`MessageBubble.vue`)
- **Files**: PascalCase for components, camelCase for utilities
- **Methods**: camelCase (`processMessage`)
- **Constants**: SCREAMING_SNAKE_CASE (`MAX_MESSAGE_LENGTH`)

## Testing Structure
- **spec/** - RSpec tests mirroring app structure
- **app/**/*.spec.js** - Vitest tests co-located with components
- **spec/factories/** - FactoryBot test data factories
- **spec/support/** - Test helpers and shared examples

## Environment Files
- **.env** - Development environment variables
- **.env.example** - Template for environment setup
- **.env.production** - Production-specific variables
- **.env.ngrok** - Local tunneling configuration

## Docker & Deployment
- **docker-compose.yaml** - Development container orchestration
- **Dockerfile** - Production container definition
- **deployment/** - Server deployment configurations
- **Procfile*** - Process definitions for different environments