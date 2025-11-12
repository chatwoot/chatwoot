# Epic 01: Infrastructure Setup

## Overview

**Duration**: 1-2 weeks
**Complexity**: Medium
**Team Size**: 2-3 engineers
**Dependencies**: None (first epic)
**Can Run Parallel**: No (foundation for everything)

## Scope

This epic establishes the foundational TypeScript/Node.js project structure, tooling, and configuration needed for the entire migration. It creates the skeleton that all subsequent epics will build upon.

**Includes:**
- NestJS project creation
- TypeScript configuration
- Build tooling (esbuild/vite)
- Linting and formatting
- Project structure
- Environment configuration
- Database connection setup
- Redis connection setup
- Logging infrastructure
- Error handling framework
- CORS configuration
- Health check endpoints
- Development scripts

**Excludes:**
- Test infrastructure (Epic 02)
- Any business logic
- Database models
- API endpoints

## Success Criteria

- ✅ TypeScript project compiles without errors
- ✅ ESLint passes with zero warnings
- ✅ Can connect to PostgreSQL
- ✅ Can connect to Redis
- ✅ Environment variables load correctly
- ✅ Health check endpoint responds
- ✅ Development server runs with hot reload
- ✅ Logging works correctly
- ✅ Documentation complete

## Estimated Size

- **12 tasks**
- **~40 hours** of engineering work
- **~5 hours** of documentation

---

## Tasks

### Task 1.1: Create NestJS Project

**Files to Create:**
- `package.json`
- `tsconfig.json`
- `nest-cli.json`
- `src/main.ts`
- `src/app.module.ts`
- `src/app.controller.ts`
- `src/app.service.ts`

**Tests First**: N/A (bootstrap task)

**Implementation Steps:**
1. ⬜ Initialize new Node.js project
   ```bash
   mkdir chatwoot-typescript
   cd chatwoot-typescript
   pnpm init
   ```

2. ⬜ Install NestJS CLI and dependencies
   ```bash
   pnpm add @nestjs/core @nestjs/common @nestjs/platform-express reflect-metadata rxjs
   pnpm add -D @nestjs/cli typescript @types/node
   ```

3. ⬜ Create basic NestJS structure
   ```bash
   npx @nestjs/cli new . --package-manager pnpm --skip-git
   ```

4. ⬜ Verify server starts
   ```bash
   pnpm start:dev
   curl http://localhost:3000
   ```

**Verification:**
```bash
pnpm start:dev
# Should see: "Nest application successfully started"
curl http://localhost:3000
# Should return: "Hello World!"
```

**Acceptance Criteria:**
- ✅ Server starts without errors
- ✅ Default route responds
- ✅ Hot reload works (change code → auto-restart)

**Complexity**: Small (S)
**Time Estimate**: 1 hour

---

### Task 1.2: Configure TypeScript Strict Mode

**Files to Modify:**
- `tsconfig.json`

**Tests First**: N/A (configuration task)

**Implementation Steps:**

1. ⬜ Update TypeScript configuration for strict mode
   ```json
   {
     "compilerOptions": {
       "module": "commonjs",
       "declaration": true,
       "removeComments": true,
       "emitDecoratorMetadata": true,
       "experimentalDecorators": true,
       "allowSyntheticDefaultImports": true,
       "target": "ES2022",
       "sourceMap": true,
       "outDir": "./dist",
       "baseUrl": "./",
       "incremental": true,
       "skipLibCheck": true,
       "strictNullChecks": true,
       "noImplicitAny": true,
       "strictBindCallApply": true,
       "forceConsistentCasingInFileNames": true,
       "noFallthroughCasesInSwitch": true,
       "strict": true,
       "noUnusedLocals": true,
       "noUnusedParameters": true,
       "noImplicitReturns": true,
       "paths": {
         "@/*": ["src/*"],
         "@test/*": ["test/*"],
         "@config/*": ["src/config/*"],
         "@models/*": ["src/models/*"],
         "@services/*": ["src/services/*"],
         "@controllers/*": ["src/controllers/*"],
         "@jobs/*": ["src/jobs/*"]
       }
     }
   }
   ```

2. ⬜ Verify compilation succeeds
   ```bash
   pnpm build
   ```

**Verification:**
```bash
pnpm build
# Should compile without errors
```

**Acceptance Criteria:**
- ✅ TypeScript compiles in strict mode
- ✅ Path aliases work
- ✅ No type errors

**Complexity**: Small (S)
**Time Estimate**: 0.5 hours

---

### Task 1.3: Set Up ESLint + Prettier

**Files to Create:**
- `.eslintrc.js`
- `.prettierrc`
- `.prettierignore`
- `.eslintignore`

**Tests First**: N/A (tooling task)

**Implementation Steps:**

1. ⬜ Install ESLint and Prettier
   ```bash
   pnpm add -D eslint @typescript-eslint/parser @typescript-eslint/eslint-plugin
   pnpm add -D prettier eslint-config-prettier eslint-plugin-prettier
   ```

2. ⬜ Create ESLint configuration
   ```javascript
   // .eslintrc.js
   module.exports = {
     parser: '@typescript-eslint/parser',
     parserOptions: {
       project: 'tsconfig.json',
       sourceType: 'module',
     },
     plugins: ['@typescript-eslint/eslint-plugin'],
     extends: [
       'plugin:@typescript-eslint/recommended',
       'plugin:prettier/recommended',
     ],
     root: true,
     env: {
       node: true,
       jest: true,
     },
     ignorePatterns: ['.eslintrc.js'],
     rules: {
       '@typescript-eslint/interface-name-prefix': 'off',
       '@typescript-eslint/explicit-function-return-type': 'warn',
       '@typescript-eslint/explicit-module-boundary-types': 'warn',
       '@typescript-eslint/no-explicit-any': 'error',
       '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
       'no-console': 'warn',
     },
   };
   ```

3. ⬜ Create Prettier configuration
   ```json
   {
     "singleQuote": true,
     "trailingComma": "all",
     "printWidth": 100,
     "tabWidth": 2,
     "semi": true,
     "arrowParens": "avoid"
   }
   ```

4. ⬜ Add lint scripts to package.json
   ```json
   {
     "scripts": {
       "lint": "eslint \"{src,apps,libs,test}/**/*.ts\"",
       "lint:fix": "eslint \"{src,apps,libs,test}/**/*.ts\" --fix",
       "format": "prettier --write \"src/**/*.ts\" \"test/**/*.ts\""
     }
   }
   ```

5. ⬜ Run linter to verify
   ```bash
   pnpm lint
   pnpm format
   ```

**Verification:**
```bash
pnpm lint
# Should pass with 0 errors
pnpm format
# Should format all files
```

**Acceptance Criteria:**
- ✅ ESLint runs without errors
- ✅ Prettier formats code consistently
- ✅ No linting warnings on existing code

**Complexity**: Small (S)
**Time Estimate**: 1 hour

---

### Task 1.4: Configure Project Structure

**Directories to Create:**
```
src/
├── common/          # Shared utilities, decorators, filters
│   ├── decorators/
│   ├── filters/
│   ├── guards/
│   ├── interceptors/
│   └── pipes/
├── config/          # Configuration modules
├── models/          # Database entities
│   └── entities/
├── controllers/     # HTTP controllers
│   ├── api/
│   │   ├── v1/
│   │   └── v2/
│   ├── public/
│   └── webhooks/
├── services/        # Business logic
├── jobs/            # Background jobs
│   ├── queues/
│   └── processors/
├── integrations/    # Third-party integrations
├── listeners/       # Event listeners
├── modules/         # Feature modules
└── database/        # Database migrations, seeders
    ├── migrations/
    └── seeders/
```

**Tests First**: N/A (structure task)

**Implementation Steps:**

1. ⬜ Create directory structure
   ```bash
   mkdir -p src/{common/{decorators,filters,guards,interceptors,pipes},config,models/entities,controllers/{api/{v1,v2},public,webhooks},services,jobs/{queues,processors},integrations,listeners,modules,database/{migrations,seeders}}
   ```

2. ⬜ Create index.ts files for each directory
   ```bash
   touch src/common/index.ts
   touch src/config/index.ts
   # ... etc
   ```

3. ⬜ Create README.md for project structure
   ```markdown
   # Chatwoot TypeScript - Project Structure

   ## Directory Organization

   - `src/common/` - Shared utilities and NestJS building blocks
   - `src/config/` - Configuration modules (database, redis, etc.)
   - `src/models/` - TypeORM entities (database models)
   - `src/controllers/` - HTTP request handlers
   - `src/services/` - Business logic layer
   - `src/jobs/` - Background job processors
   - `src/integrations/` - Third-party API integrations
   - `src/listeners/` - Event-driven listeners
   - `src/modules/` - Feature modules
   - `src/database/` - Migrations and seeders
   ```

**Verification:**
```bash
tree src -L 2
# Should show organized structure
```

**Acceptance Criteria:**
- ✅ All directories created
- ✅ Structure documented
- ✅ Follows NestJS best practices

**Complexity**: Small (S)
**Time Estimate**: 0.5 hours

---

### Task 1.5: Set Up Environment Configuration

**Files to Create:**
- `.env.example`
- `src/config/environment.config.ts`
- `src/config/config.module.ts`

**Tests First**: N/A (configuration task)

**Implementation Steps:**

1. ⬜ Install configuration dependencies
   ```bash
   pnpm add @nestjs/config dotenv
   pnpm add -D @types/node
   ```

2. ⬜ Create environment variables template
   ```bash
   # .env.example
   NODE_ENV=development
   PORT=3000

   # Database
   DATABASE_HOST=localhost
   DATABASE_PORT=5432
   DATABASE_USER=postgres
   DATABASE_PASSWORD=postgres
   DATABASE_NAME=chatwoot_development
   DATABASE_URL=postgresql://postgres:postgres@localhost:5432/chatwoot_development

   # Redis
   REDIS_HOST=localhost
   REDIS_PORT=6379
   REDIS_PASSWORD=
   REDIS_URL=redis://localhost:6379

   # JWT
   JWT_SECRET=your-secret-key-change-in-production
   JWT_ACCESS_EXPIRY=15m
   JWT_REFRESH_EXPIRY=7d

   # CORS
   CORS_ORIGIN=http://localhost:3000,http://localhost:8080

   # Logging
   LOG_LEVEL=info

   # Monitoring
   SENTRY_DSN=
   ```

3. ⬜ Create configuration module
   ```typescript
   // src/config/environment.config.ts
   import { registerAs } from '@nestjs/config';

   export default registerAs('app', () => ({
     nodeEnv: process.env.NODE_ENV || 'development',
     port: parseInt(process.env.PORT, 10) || 3000,
     database: {
       host: process.env.DATABASE_HOST || 'localhost',
       port: parseInt(process.env.DATABASE_PORT, 10) || 5432,
       username: process.env.DATABASE_USER || 'postgres',
       password: process.env.DATABASE_PASSWORD || 'postgres',
       database: process.env.DATABASE_NAME || 'chatwoot_development',
       url: process.env.DATABASE_URL,
     },
     redis: {
       host: process.env.REDIS_HOST || 'localhost',
       port: parseInt(process.env.REDIS_PORT, 10) || 6379,
       password: process.env.REDIS_PASSWORD || undefined,
       url: process.env.REDIS_URL,
     },
     jwt: {
       secret: process.env.JWT_SECRET || 'change-me',
       accessExpiry: process.env.JWT_ACCESS_EXPIRY || '15m',
       refreshExpiry: process.env.JWT_REFRESH_EXPIRY || '7d',
     },
     cors: {
       origin: process.env.CORS_ORIGIN?.split(',') || ['http://localhost:3000'],
     },
     logging: {
       level: process.env.LOG_LEVEL || 'info',
     },
     sentry: {
       dsn: process.env.SENTRY_DSN,
     },
   }));
   ```

4. ⬜ Create config module
   ```typescript
   // src/config/config.module.ts
   import { Module } from '@nestjs/common';
   import { ConfigModule as NestConfigModule } from '@nestjs/config';
   import environmentConfig from './environment.config';

   @Module({
     imports: [
       NestConfigModule.forRoot({
         isGlobal: true,
         load: [environmentConfig],
         envFilePath: ['.env.local', '.env'],
       }),
     ],
   })
   export class ConfigModule {}
   ```

5. ⬜ Import in AppModule
   ```typescript
   // src/app.module.ts
   import { ConfigModule } from './config/config.module';

   @Module({
     imports: [ConfigModule],
   })
   export class AppModule {}
   ```

6. ⬜ Create .env file (copy from .env.example)
   ```bash
   cp .env.example .env
   ```

**Verification:**
```bash
pnpm start:dev
# Should load environment variables
# Check logs for "Nest application successfully started on port 3000"
```

**Acceptance Criteria:**
- ✅ Environment variables load from .env
- ✅ Configuration is type-safe
- ✅ Can access config in services via dependency injection

**Complexity**: Medium (M)
**Time Estimate**: 2 hours

---

### Task 1.6: Configure Database Connection (TypeORM)

**Files to Create:**
- `src/config/database.config.ts`
- `src/database/database.module.ts`
- `ormconfig.ts`

**Tests First**: N/A (infrastructure task)

**Implementation Steps:**

1. ⬜ Install TypeORM and PostgreSQL driver
   ```bash
   pnpm add @nestjs/typeorm typeorm pg
   ```

2. ⬜ Create database configuration
   ```typescript
   // src/config/database.config.ts
   import { TypeOrmModuleOptions } from '@nestjs/typeorm';
   import { ConfigService } from '@nestjs/config';

   export const getDatabaseConfig = (configService: ConfigService): TypeOrmModuleOptions => ({
     type: 'postgres',
     host: configService.get<string>('app.database.host'),
     port: configService.get<number>('app.database.port'),
     username: configService.get<string>('app.database.username'),
     password: configService.get<string>('app.database.password'),
     database: configService.get<string>('app.database.database'),
     entities: [__dirname + '/../**/*.entity{.ts,.js}'],
     migrations: [__dirname + '/../database/migrations/*{.ts,.js}'],
     synchronize: false, // Never true in production
     logging: configService.get<string>('app.nodeEnv') === 'development',
     ssl: configService.get<string>('app.nodeEnv') === 'production' ? { rejectUnauthorized: false } : false,
   });
   ```

3. ⬜ Create database module
   ```typescript
   // src/database/database.module.ts
   import { Module } from '@nestjs/common';
   import { TypeOrmModule } from '@nestjs/typeorm';
   import { ConfigService } from '@nestjs/config';
   import { getDatabaseConfig } from '../config/database.config';

   @Module({
     imports: [
       TypeOrmModule.forRootAsync({
         inject: [ConfigService],
         useFactory: (configService: ConfigService) => getDatabaseConfig(configService),
       }),
     ],
   })
   export class DatabaseModule {}
   ```

4. ⬜ Import DatabaseModule in AppModule
   ```typescript
   // src/app.module.ts
   import { DatabaseModule } from './database/database.module';

   @Module({
     imports: [ConfigModule, DatabaseModule],
   })
   export class AppModule {}
   ```

5. ⬜ Test database connection
   ```bash
   pnpm start:dev
   # Should see TypeORM logs connecting to database
   ```

**Verification:**
```bash
pnpm start:dev
# Check logs for successful database connection
# Should see: "Database connection established"
```

**Acceptance Criteria:**
- ✅ Connects to PostgreSQL successfully
- ✅ TypeORM initialized
- ✅ Can create entities (tested in Epic 03)

**Complexity**: Medium (M)
**Time Estimate**: 2 hours

---

### Task 1.7: Configure Redis Connection

**Files to Create:**
- `src/config/redis.config.ts`
- `src/redis/redis.module.ts`

**Tests First**: N/A (infrastructure task)

**Implementation Steps:**

1. ⬜ Install Redis client
   ```bash
   pnpm add ioredis
   pnpm add -D @types/ioredis
   ```

2. ⬜ Create Redis configuration
   ```typescript
   // src/config/redis.config.ts
   import { RedisOptions } from 'ioredis';
   import { ConfigService } from '@nestjs/config';

   export const getRedisConfig = (configService: ConfigService): RedisOptions => ({
     host: configService.get<string>('app.redis.host'),
     port: configService.get<number>('app.redis.port'),
     password: configService.get<string>('app.redis.password'),
     retryStrategy: (times: number) => Math.min(times * 50, 2000),
     maxRetriesPerRequest: 3,
   });
   ```

3. ⬜ Create Redis module
   ```typescript
   // src/redis/redis.module.ts
   import { Module, Global } from '@nestjs/common';
   import { ConfigService } from '@nestjs/config';
   import Redis from 'ioredis';
   import { getRedisConfig } from '../config/redis.config';

   export const REDIS_CLIENT = 'REDIS_CLIENT';

   @Global()
   @Module({
     providers: [
       {
         provide: REDIS_CLIENT,
         inject: [ConfigService],
         useFactory: (configService: ConfigService) => {
           const config = getRedisConfig(configService);
           return new Redis(config);
         },
       },
     ],
     exports: [REDIS_CLIENT],
   })
   export class RedisModule {}
   ```

4. ⬜ Import RedisModule in AppModule
   ```typescript
   // src/app.module.ts
   import { RedisModule } from './redis/redis.module';

   @Module({
     imports: [ConfigModule, DatabaseModule, RedisModule],
   })
   export class AppModule {}
   ```

5. ⬜ Test Redis connection
   ```bash
   pnpm start:dev
   # Check logs for Redis connection
   ```

**Verification:**
```bash
pnpm start:dev
# Check logs for successful Redis connection
redis-cli ping
# Should return: PONG
```

**Acceptance Criteria:**
- ✅ Connects to Redis successfully
- ✅ Can inject Redis client in services
- ✅ Reconnection logic works

**Complexity**: Medium (M)
**Time Estimate**: 1.5 hours

---

### Task 1.8: Configure Logging (Winston)

**Files to Create:**
- `src/common/logger/logger.module.ts`
- `src/common/logger/logger.service.ts`

**Tests First**: N/A (infrastructure task)

**Implementation Steps:**

1. ⬜ Install Winston
   ```bash
   pnpm add winston nest-winston
   ```

2. ⬜ Create logger service
   ```typescript
   // src/common/logger/logger.service.ts
   import { Injectable, LoggerService as NestLoggerService } from '@nestjs/common';
   import * as winston from 'winston';

   @Injectable()
   export class LoggerService implements NestLoggerService {
     private logger: winston.Logger;

     constructor() {
       this.logger = winston.createLogger({
         level: process.env.LOG_LEVEL || 'info',
         format: winston.format.combine(
           winston.format.timestamp(),
           winston.format.errors({ stack: true }),
           winston.format.json(),
         ),
         transports: [
           new winston.transports.Console({
             format: winston.format.combine(
               winston.format.colorize(),
               winston.format.simple(),
             ),
           }),
         ],
       });
     }

     log(message: string, context?: string): void {
       this.logger.info(message, { context });
     }

     error(message: string, trace?: string, context?: string): void {
       this.logger.error(message, { trace, context });
     }

     warn(message: string, context?: string): void {
       this.logger.warn(message, { context });
     }

     debug(message: string, context?: string): void {
       this.logger.debug(message, { context });
     }

     verbose(message: string, context?: string): void {
       this.logger.verbose(message, { context });
     }
   }
   ```

3. ⬜ Create logger module
   ```typescript
   // src/common/logger/logger.module.ts
   import { Module, Global } from '@nestjs/common';
   import { LoggerService } from './logger.service';

   @Global()
   @Module({
     providers: [LoggerService],
     exports: [LoggerService],
   })
   export class LoggerModule {}
   ```

4. ⬜ Use logger in main.ts
   ```typescript
   // src/main.ts
   import { LoggerService } from './common/logger/logger.service';

   async function bootstrap() {
     const app = await NestFactory.create(AppModule, {
       logger: new LoggerService(),
     });
     // ...
   }
   ```

**Verification:**
```bash
pnpm start:dev
# Should see formatted logs in console
```

**Acceptance Criteria:**
- ✅ Logs are formatted consistently
- ✅ Log levels work correctly
- ✅ Can inject logger in services

**Complexity**: Medium (M)
**Time Estimate**: 1.5 hours

---

### Task 1.9: Set Up Global Error Handling

**Files to Create:**
- `src/common/filters/http-exception.filter.ts`
- `src/common/filters/all-exceptions.filter.ts`

**Tests First**: N/A (infrastructure task)

**Implementation Steps:**

1. ⬜ Create HTTP exception filter
   ```typescript
   // src/common/filters/http-exception.filter.ts
   import { ExceptionFilter, Catch, ArgumentsHost, HttpException, HttpStatus } from '@nestjs/common';
   import { Request, Response } from 'express';
   import { LoggerService } from '../logger/logger.service';

   @Catch(HttpException)
   export class HttpExceptionFilter implements ExceptionFilter {
     constructor(private logger: LoggerService) {}

     catch(exception: HttpException, host: ArgumentsHost): void {
       const ctx = host.switchToHttp();
       const response = ctx.getResponse<Response>();
       const request = ctx.getRequest<Request>();
       const status = exception.getStatus();
       const exceptionResponse = exception.getResponse();

       const errorResponse = {
         statusCode: status,
         timestamp: new Date().toISOString(),
         path: request.url,
         method: request.method,
         message: typeof exceptionResponse === 'string' ? exceptionResponse : (exceptionResponse as any).message,
       };

       this.logger.error(`${request.method} ${request.url}`, JSON.stringify(errorResponse), 'HttpExceptionFilter');

       response.status(status).json(errorResponse);
     }
   }
   ```

2. ⬜ Create all exceptions filter
   ```typescript
   // src/common/filters/all-exceptions.filter.ts
   import { ExceptionFilter, Catch, ArgumentsHost, HttpStatus } from '@nestjs/common';
   import { Request, Response } from 'express';
   import { LoggerService } from '../logger/logger.service';

   @Catch()
   export class AllExceptionsFilter implements ExceptionFilter {
     constructor(private logger: LoggerService) {}

     catch(exception: unknown, host: ArgumentsHost): void {
       const ctx = host.switchToHttp();
       const response = ctx.getResponse<Response>();
       const request = ctx.getRequest<Request>();

       const status = HttpStatus.INTERNAL_SERVER_ERROR;
       const message = exception instanceof Error ? exception.message : 'Internal server error';

       const errorResponse = {
         statusCode: status,
         timestamp: new Date().toISOString(),
         path: request.url,
         method: request.method,
         message,
       };

       this.logger.error(`${request.method} ${request.url}`, exception instanceof Error ? exception.stack : '', 'AllExceptionsFilter');

       response.status(status).json(errorResponse);
     }
   }
   ```

3. ⬜ Register filters globally
   ```typescript
   // src/main.ts
   import { HttpExceptionFilter } from './common/filters/http-exception.filter';
   import { AllExceptionsFilter } from './common/filters/all-exceptions.filter';

   async function bootstrap() {
     const app = await NestFactory.create(AppModule);
     const logger = app.get(LoggerService);

     app.useGlobalFilters(
       new AllExceptionsFilter(logger),
       new HttpExceptionFilter(logger),
     );
     // ...
   }
   ```

**Verification:**
```bash
# Test error handling
curl http://localhost:3000/nonexistent
# Should return formatted error JSON
```

**Acceptance Criteria:**
- ✅ All errors return consistent JSON format
- ✅ Errors are logged
- ✅ Stack traces captured in logs

**Complexity**: Medium (M)
**Time Estimate**: 2 hours

---

### Task 1.10: Configure CORS

**Files to Modify:**
- `src/main.ts`

**Tests First**: N/A (configuration task)

**Implementation Steps:**

1. ⬜ Enable CORS in main.ts
   ```typescript
   // src/main.ts
   import { ConfigService } from '@nestjs/config';

   async function bootstrap() {
     const app = await NestFactory.create(AppModule);
     const configService = app.get(ConfigService);

     app.enableCors({
       origin: configService.get<string[]>('app.cors.origin'),
       credentials: true,
       methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
       allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
     });

     // ...
   }
   ```

2. ⬜ Test CORS with preflight request
   ```bash
   curl -X OPTIONS http://localhost:3000/api/v1/health \
     -H "Origin: http://localhost:8080" \
     -H "Access-Control-Request-Method: GET"
   ```

**Verification:**
```bash
# Should return CORS headers
curl -v -X OPTIONS http://localhost:3000/api/v1/health -H "Origin: http://localhost:8080"
# Check for: Access-Control-Allow-Origin header
```

**Acceptance Criteria:**
- ✅ CORS enabled for configured origins
- ✅ Preflight requests handled
- ✅ Credentials allowed

**Complexity**: Small (S)
**Time Estimate**: 0.5 hours

---

### Task 1.11: Create Health Check Endpoints

**Files to Create:**
- `src/health/health.controller.ts`
- `src/health/health.module.ts`

**Tests First**: N/A (simple endpoint)

**Implementation Steps:**

1. ⬜ Install health check package
   ```bash
   pnpm add @nestjs/terminus
   ```

2. ⬜ Create health controller
   ```typescript
   // src/health/health.controller.ts
   import { Controller, Get } from '@nestjs/common';
   import { HealthCheck, HealthCheckService, TypeOrmHealthIndicator, MemoryHealthIndicator } from '@nestjs/terminus';
   import { InjectRedis } from '@nestjs-modules/ioredis';
   import Redis from 'ioredis';

   @Controller('health')
   export class HealthController {
     constructor(
       private health: HealthCheckService,
       private db: TypeOrmHealthIndicator,
       private memory: MemoryHealthIndicator,
       @InjectRedis() private redis: Redis,
     ) {}

     @Get()
     @HealthCheck()
     check() {
       return this.health.check([
         () => this.db.pingCheck('database'),
         () => this.memory.checkHeap('memory_heap', 300 * 1024 * 1024),
         async () => {
           const result = await this.redis.ping();
           return { redis: { status: result === 'PONG' ? 'up' : 'down' } };
         },
       ]);
     }

     @Get('ready')
     ready() {
       return { status: 'ready', timestamp: new Date().toISOString() };
     }

     @Get('live')
     live() {
       return { status: 'alive', timestamp: new Date().toISOString() };
     }
   }
   ```

3. ⬜ Create health module
   ```typescript
   // src/health/health.module.ts
   import { Module } from '@nestjs/common';
   import { TerminusModule } from '@nestjs/terminus';
   import { HealthController } from './health.controller';

   @Module({
     imports: [TerminusModule],
     controllers: [HealthController],
   })
   export class HealthModule {}
   ```

4. ⬜ Import HealthModule in AppModule

5. ⬜ Test health endpoints
   ```bash
   curl http://localhost:3000/health
   curl http://localhost:3000/health/ready
   curl http://localhost:3000/health/live
   ```

**Verification:**
```bash
curl http://localhost:3000/health
# Should return: { "status": "ok", "info": { "database": { "status": "up" }, ... } }
```

**Acceptance Criteria:**
- ✅ Health endpoint checks database
- ✅ Health endpoint checks Redis
- ✅ Health endpoint checks memory
- ✅ Ready/live endpoints respond

**Complexity**: Medium (M)
**Time Estimate**: 1.5 hours

---

### Task 1.12: Create Development Scripts

**Files to Modify:**
- `package.json`

**Tests First**: N/A (tooling task)

**Implementation Steps:**

1. ⬜ Add npm scripts
   ```json
   {
     "scripts": {
       "prebuild": "rimraf dist",
       "build": "nest build",
       "format": "prettier --write \"src/**/*.ts\" \"test/**/*.ts\"",
       "start": "nest start",
       "start:dev": "nest start --watch",
       "start:debug": "nest start --debug --watch",
       "start:prod": "node dist/main",
       "lint": "eslint \"{src,apps,libs,test}/**/*.ts\" --fix",
       "test": "vitest",
       "test:watch": "vitest --watch",
       "test:cov": "vitest --coverage",
       "test:e2e": "vitest --config ./test/vitest-e2e.config.ts",
       "typeorm": "typeorm-ts-node-commonjs",
       "migration:generate": "npm run typeorm -- migration:generate",
       "migration:run": "npm run typeorm -- migration:run",
       "migration:revert": "npm run typeorm -- migration:revert"
     }
   }
   ```

2. ⬜ Install rimraf
   ```bash
   pnpm add -D rimraf
   ```

3. ⬜ Test all scripts
   ```bash
   pnpm build
   pnpm lint
   pnpm start:dev
   ```

**Verification:**
```bash
pnpm build  # Should build successfully
pnpm start:dev  # Should start dev server
```

**Acceptance Criteria:**
- ✅ All scripts work correctly
- ✅ Build produces dist/ folder
- ✅ Dev server has hot reload

**Complexity**: Small (S)
**Time Estimate**: 0.5 hours

---

## Dependencies

### Package Dependencies

```json
{
  "dependencies": {
    "@nestjs/common": "^10.0.0",
    "@nestjs/core": "^10.0.0",
    "@nestjs/config": "^3.0.0",
    "@nestjs/platform-express": "^10.0.0",
    "@nestjs/typeorm": "^10.0.0",
    "@nestjs/terminus": "^10.0.0",
    "typeorm": "^0.3.17",
    "pg": "^8.11.0",
    "ioredis": "^5.3.2",
    "winston": "^3.10.0",
    "nest-winston": "^1.9.4",
    "reflect-metadata": "^0.1.13",
    "rxjs": "^7.8.1",
    "dotenv": "^16.3.1"
  },
  "devDependencies": {
    "@nestjs/cli": "^10.0.0",
    "@nestjs/schematics": "^10.0.0",
    "@nestjs/testing": "^10.0.0",
    "@types/express": "^4.17.17",
    "@types/node": "^20.0.0",
    "@typescript-eslint/eslint-plugin": "^6.0.0",
    "@typescript-eslint/parser": "^6.0.0",
    "eslint": "^8.42.0",
    "eslint-config-prettier": "^9.0.0",
    "eslint-plugin-prettier": "^5.0.0",
    "prettier": "^3.0.0",
    "rimraf": "^5.0.1",
    "typescript": "^5.1.3"
  }
}
```

---

## Rollback Plan

**If Epic 01 needs to be abandoned:**

1. Delete `chatwoot-typescript/` directory
2. No changes to Rails app
3. No database changes
4. No production impact

**Time to Rollback**: < 1 minute

---

## Documentation Checklist

- ⬜ README.md (project overview)
- ⬜ ARCHITECTURE.md (infrastructure decisions)
- ⬜ DEVELOPMENT.md (getting started guide)
- ⬜ ENV_VARS.md (environment variables)
- ⬜ SCRIPTS.md (npm scripts reference)

---

## Notes

- This epic has no dependencies on existing Rails code
- Can be developed completely in parallel
- Sets foundation for all future epics
- Keep it simple - add complexity in later epics

---

**Epic Status**: 🟡 Ready to Start
**Estimated Duration**: 1-2 weeks
**Next Epic**: Epic 02 - Test Infrastructure
