# Chatwoot TypeScript Project Structure

This document describes the organization and purpose of directories in the Chatwoot TypeScript/NestJS application.

## Root Directory Structure

```
chatwoot-typescript/
├── src/                    # Source code
├── test/                   # Test files (E2E and unit tests)
├── dist/                   # Compiled output
└── node_modules/           # Dependencies
```

## Source Directory (`src/`)

### Core Application Files
- `main.ts` - Application bootstrap and entry point
- `app.module.ts` - Root application module
- `app.controller.ts` - Default application controller
- `app.service.ts` - Default application service

### Directory Structure

#### `common/`
Shared utilities, decorators, and cross-cutting concerns used throughout the application.

- **`decorators/`** - Custom decorators (e.g., @CurrentUser, @Roles, @ApiAuth)
- **`filters/`** - Exception filters for error handling
- **`guards/`** - Route guards for authentication and authorization
- **`interceptors/`** - Request/response interceptors (logging, transformation)
- **`pipes/`** - Validation and transformation pipes

#### `config/`
Configuration modules and files for various application settings.

- Environment configuration
- Database configuration
- Redis configuration
- AWS/Storage configuration
- Email/SMTP configuration
- Third-party integrations configuration

#### `models/`
Data models and entity definitions.

- **`entities/`** - TypeORM entities representing database tables
  - Account, User, Conversation, Message, Contact, etc.
- DTOs (Data Transfer Objects)
- Interfaces and types

#### `controllers/`
HTTP request handlers organized by API version and purpose.

- **`api/`** - Main API endpoints
  - **`v1/`** - Version 1 API controllers
  - **`v2/`** - Version 2 API controllers (future)
- **`public/`** - Public endpoints (no authentication required)
- **`webhooks/`** - Webhook handlers for external integrations

#### `services/`
Business logic and service layer.

- Core business services (AccountService, UserService, ConversationService, etc.)
- Integration services
- Notification services
- File processing services

#### `jobs/`
Background job processing using BullMQ.

- **`queues/`** - Queue definitions and configurations
- **`processors/`** - Job processors and workers
  - Email sending
  - Report generation
  - Data synchronization
  - Cleanup tasks

#### `integrations/`
Third-party service integrations.

- Slack integration
- WhatsApp integration
- Facebook/Instagram integration
- Email providers (SMTP, SendGrid, Mailgun)
- SMS providers (Twilio, etc.)
- Storage providers (S3, GCS, etc.)

#### `listeners/`
Event listeners and handlers for application events.

- Domain events
- WebSocket events
- Database events
- System events

#### `modules/`
Feature modules organized by business domain.

Each module encapsulates related controllers, services, and entities:
- Accounts module
- Users module
- Conversations module
- Messages module
- Contacts module
- Inbox module
- Teams module
- Agents module
- Campaigns module
- Webhooks module
- Reports module

#### `database/`
Database-related files.

- **`migrations/`** - TypeORM migrations for schema changes
- **`seeders/`** - Database seeding scripts for development/testing

## Path Aliases

TypeScript path aliases are configured for cleaner imports:

```typescript
import { User } from '@models/entities/user.entity';
import { DatabaseConfig } from '@config/database.config';
import { CurrentUser } from '@/common/decorators/current-user.decorator';
import { UserService } from '@services/user.service';
```

Available aliases:
- `@/*` → `src/*`
- `@test/*` → `test/*`
- `@config/*` → `src/config/*`
- `@models/*` → `src/models/*`
- `@services/*` → `src/services/*`
- `@controllers/*` → `src/controllers/*`
- `@jobs/*` → `src/jobs/*`

## Module Organization Pattern

Each feature module follows this structure:

```
modules/
└── feature-name/
    ├── feature-name.module.ts       # NestJS module definition
    ├── feature-name.controller.ts   # HTTP endpoints
    ├── feature-name.service.ts      # Business logic
    ├── feature-name.entity.ts       # Database entity
    ├── dto/                         # Data transfer objects
    │   ├── create-feature.dto.ts
    │   └── update-feature.dto.ts
    └── tests/                       # Unit tests
        ├── feature-name.controller.spec.ts
        └── feature-name.service.spec.ts
```

## Naming Conventions

- **Files**: kebab-case (e.g., `user-profile.service.ts`)
- **Classes**: PascalCase (e.g., `UserProfileService`)
- **Interfaces**: PascalCase with 'I' prefix (e.g., `IUserProfile`)
- **Constants**: SCREAMING_SNAKE_CASE (e.g., `MAX_UPLOAD_SIZE`)
- **Functions/Methods**: camelCase (e.g., `getUserProfile()`)

## Import Order

Follow this import order in all files:

1. Node.js built-in modules
2. External dependencies (@nestjs, etc.)
3. Internal modules using path aliases
4. Relative imports
5. Types and interfaces

```typescript
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { User } from '@models/entities/user.entity';
import { DatabaseService } from '@config/database.service';

import { UserDto } from './dto/user.dto';
import type { IUserService } from './interfaces/user-service.interface';
```

## Best Practices

1. **Single Responsibility**: Each file should have one clear purpose
2. **Dependency Injection**: Use NestJS DI container for all dependencies
3. **Type Safety**: Avoid `any` type; use strict TypeScript
4. **Error Handling**: Use custom exceptions and exception filters
5. **Validation**: Use class-validator DTOs for input validation
6. **Testing**: Write unit tests alongside implementation
7. **Documentation**: Add JSDoc comments for public APIs
8. **Async/Await**: Prefer async/await over callbacks or raw promises
