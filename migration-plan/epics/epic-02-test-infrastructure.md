# Epic 02: Test Infrastructure & CI/CD

## Overview

**Duration**: 1-2 weeks
**Complexity**: Medium
**Team Size**: 2-3 engineers
**Dependencies**: Epic 01 (Infrastructure Setup)
**Can Run Parallel**: No (foundational)

## Scope

This epic establishes the testing framework, patterns, and CI/CD pipeline that will enable Test-Driven Development (TDD) for all subsequent epics.

**Includes:**
- Vitest configuration
- Test database setup
- Factory pattern implementation (FactoryBot equivalent)
- Supertest for HTTP testing
- Coverage reporting
- Test helpers and utilities
- CI/CD pipeline (GitHub Actions)
- Pre-commit hooks
- Test documentation

**Excludes:**
- Actual model/controller/service tests (those come in later epics)
- E2E testing setup (can add later if needed)

## Success Criteria

- ✅ Vitest runs successfully
- ✅ Test database connects and resets between tests
- ✅ Factories can create test data
- ✅ HTTP tests work with Supertest
- ✅ Coverage reports generate
- ✅ CI pipeline runs on every PR
- ✅ Pre-commit hooks prevent bad commits
- ✅ 100% of infrastructure tests passing

## Estimated Size

- **8 tasks**
- **~30 hours** of engineering work
- **~3 hours** of documentation

---

## Tasks

### Task 2.1: Configure Vitest

**Files to Create:**
- `vitest.config.ts`
- `test/setup.ts`
- `test/teardown.ts`

**Tests First**: Write a simple test to verify Vitest works

**Implementation Steps:**

1. ⬜ Install Vitest and related packages
   ```bash
   pnpm add -D vitest @vitest/coverage-v8 @vitest/ui
   pnpm add -D @types/node
   ```

2. ⬜ Create Vitest configuration
   ```typescript
   // vitest.config.ts
   import { defineConfig } from 'vitest/config';
   import { resolve } from 'path';

   export default defineConfig({
     test: {
       globals: true,
       environment: 'node',
       setupFiles: ['./test/setup.ts'],
       globalSetup: ['./test/global-setup.ts'],
       coverage: {
         provider: 'v8',
         reporter: ['text', 'json', 'html', 'lcov'],
         exclude: [
           'node_modules/',
           'test/',
           'dist/',
           '**/*.spec.ts',
           '**/*.test.ts',
           '**/*.config.ts',
           '**/index.ts',
         ],
         threshold: {
           lines: 90,
           functions: 90,
           branches: 90,
           statements: 90,
         },
       },
       pool: 'forks',
       poolOptions: {
         forks: {
           singleFork: false,
         },
       },
       testTimeout: 10000,
     },
     resolve: {
       alias: {
         '@': resolve(__dirname, './src'),
         '@test': resolve(__dirname, './test'),
       },
     },
   });
   ```

3. ⬜ Create test setup file
   ```typescript
   // test/setup.ts
   import { config } from 'dotenv';
   import { resolve } from 'path';

   // Load test environment variables
   config({ path: resolve(__dirname, '../.env.test') });

   // Set NODE_ENV to test
   process.env.NODE_ENV = 'test';

   // Mock console methods if needed
   global.console = {
     ...console,
     error: vi.fn(),
     warn: vi.fn(),
   };
   ```

4. ⬜ Write a simple test to verify setup
   ```typescript
   // test/sanity.spec.ts
   import { describe, it, expect } from 'vitest';

   describe('Vitest Setup', () => {
     it('should run tests', () => {
       expect(true).toBe(true);
     });

     it('should support async tests', async () => {
       const result = await Promise.resolve(42);
       expect(result).toBe(42);
     });

     it('should have access to environment variables', () => {
       expect(process.env.NODE_ENV).toBe('test');
     });
   });
   ```

5. ⬜ Run test to verify
   ```bash
   pnpm test
   ```

**Verification:**
```bash
pnpm test
# Should pass 3 tests
pnpm test:cov
# Should generate coverage report
```

**Acceptance Criteria:**
- ✅ Vitest runs successfully
- ✅ Tests pass
- ✅ Path aliases work (@, @test)
- ✅ Coverage reports generate

**Complexity**: Medium (M)
**Time Estimate**: 2 hours

---

### Task 2.2: Set Up Test Database

**Files to Create:**
- `.env.test`
- `test/database/test-database.ts`
- `test/database/database-cleaner.ts`
- `test/global-setup.ts`

**Tests First**: Write test that uses database

**Implementation Steps:**

1. ⬜ Create test environment file
   ```bash
   # .env.test
   NODE_ENV=test
   PORT=3001

   DATABASE_HOST=localhost
   DATABASE_PORT=5432
   DATABASE_USER=postgres
   DATABASE_PASSWORD=postgres
   DATABASE_NAME=chatwoot_test
   DATABASE_URL=postgresql://postgres:postgres@localhost:5432/chatwoot_test

   REDIS_URL=redis://localhost:6379/1

   JWT_SECRET=test-secret
   LOG_LEVEL=error
   ```

2. ⬜ Create test database utility
   ```typescript
   // test/database/test-database.ts
   import { DataSource } from 'typeorm';
   import { getDatabaseConfig } from '@/config/database.config';
   import { ConfigService } from '@nestjs/config';

   let testDataSource: DataSource;

   export async function createTestDatabase(): Promise<DataSource> {
     const configService = new ConfigService();
     const config = getDatabaseConfig(configService);

     testDataSource = new DataSource({
       ...config,
       synchronize: true, // Auto-create schema for tests
       dropSchema: true, // Clean slate each run
       logging: false,
     } as any);

     await testDataSource.initialize();
     return testDataSource;
   }

   export async function closeTestDatabase(): Promise<void> {
     if (testDataSource?.isInitialized) {
       await testDataSource.destroy();
     }
   }

   export function getTestDataSource(): DataSource {
     return testDataSource;
   }
   ```

3. ⬜ Create database cleaner
   ```typescript
   // test/database/database-cleaner.ts
   import { getTestDataSource } from './test-database';

   export async function cleanDatabase(): Promise<void> {
     const dataSource = getTestDataSource();
     const entities = dataSource.entityMetadatas;

     for (const entity of entities) {
       const repository = dataSource.getRepository(entity.name);
       await repository.query(`TRUNCATE TABLE "${entity.tableName}" CASCADE;`);
     }
   }

   export async function resetSequences(): Promise<void> {
     const dataSource = getTestDataSource();
     const entities = dataSource.entityMetadatas;

     for (const entity of entities) {
       if (entity.tableName) {
         await dataSource.query(
           `ALTER SEQUENCE IF EXISTS "${entity.tableName}_id_seq" RESTART WITH 1;`
         );
       }
     }
   }
   ```

4. ⬜ Create global setup
   ```typescript
   // test/global-setup.ts
   import { createTestDatabase, closeTestDatabase } from './database/test-database';

   export async function setup(): Promise<void> {
     await createTestDatabase();
   }

   export async function teardown(): Promise<void> {
     await closeTestDatabase();
   }
   ```

5. ⬜ Update test/setup.ts to clean database before each test
   ```typescript
   // test/setup.ts
   import { beforeEach, afterAll } from 'vitest';
   import { cleanDatabase, resetSequences } from './database/database-cleaner';
   import { closeTestDatabase } from './database/test-database';

   beforeEach(async () => {
     await cleanDatabase();
     await resetSequences();
   });

   afterAll(async () => {
     await closeTestDatabase();
   });
   ```

6. ⬜ Write test to verify database setup
   ```typescript
   // test/database/database-setup.spec.ts
   import { describe, it, expect } from 'vitest';
   import { getTestDataSource } from './test-database';

   describe('Test Database Setup', () => {
     it('should have database connection', () => {
       const dataSource = getTestDataSource();
       expect(dataSource).toBeDefined();
       expect(dataSource.isInitialized).toBe(true);
     });

     it('should clean database between tests', async () => {
       // This will be more meaningful once we have entities
       const dataSource = getTestDataSource();
       expect(dataSource).toBeDefined();
     });
   });
   ```

**Verification:**
```bash
pnpm test test/database
# Should connect to test database and run tests
```

**Acceptance Criteria:**
- ✅ Test database connects
- ✅ Schema creates automatically
- ✅ Database cleans between tests
- ✅ Sequences reset

**Complexity**: High (H)
**Time Estimate**: 4 hours

---

### Task 2.3: Create Factory System

**Files to Create:**
- `test/factories/base.factory.ts`
- `test/factories/user.factory.ts` (example)
- `test/factories/index.ts`

**Tests First**: Write tests for factory

**Implementation Steps:**

1. ⬜ Install faker
   ```bash
   pnpm add -D @faker-js/faker
   ```

2. ⬜ Create base factory class
   ```typescript
   // test/factories/base.factory.ts
   import { DeepPartial, Repository } from 'typeorm';
   import { getTestDataSource } from '../database/test-database';

   export abstract class BaseFactory<T> {
     protected abstract getRepository(): Repository<T>;
     protected abstract getDefaultAttributes(): DeepPartial<T>;

     build(overrides?: DeepPartial<T>): T {
       const defaults = this.getDefaultAttributes();
       return this.getRepository().create({ ...defaults, ...overrides });
     }

     async create(overrides?: DeepPartial<T>): Promise<T> {
       const entity = this.build(overrides);
       return this.getRepository().save(entity);
     }

     async createMany(count: number, overrides?: DeepPartial<T>): Promise<T[]> {
       const entities = Array.from({ length: count }, () => this.build(overrides));
       return this.getRepository().save(entities);
     }

     async createWithRelations(
       overrides?: DeepPartial<T>,
       relations?: Record<string, any>
     ): Promise<T> {
       const entity = await this.create(overrides);
       if (relations) {
         Object.assign(entity, relations);
         return this.getRepository().save(entity);
       }
       return entity;
     }
   }
   ```

3. ⬜ Create example user factory (will be replaced with real User entity later)
   ```typescript
   // test/factories/user.factory.ts
   import { faker } from '@faker-js/faker';
   import { Repository } from 'typeorm';
   import { BaseFactory } from './base.factory';
   import { getTestDataSource } from '../database/test-database';

   // Placeholder interface (will be replaced with real User entity)
   interface User {
     id?: string;
     email: string;
     name: string;
     password: string;
     role: string;
     createdAt?: Date;
     updatedAt?: Date;
   }

   export class UserFactory extends BaseFactory<User> {
     protected getRepository(): Repository<User> {
       return getTestDataSource().getRepository('User');
     }

     protected getDefaultAttributes(): Partial<User> {
       return {
         email: faker.internet.email(),
         name: faker.person.fullName(),
         password: faker.internet.password(),
         role: 'agent',
       };
     }

     withRole(role: string): UserFactory {
       // Method chaining support
       return this;
     }

     asAdmin(): UserFactory {
       return this.withRole('administrator');
     }

     asAgent(): UserFactory {
       return this.withRole('agent');
     }
   }
   ```

4. ⬜ Create factory index
   ```typescript
   // test/factories/index.ts
   export * from './user.factory';
   export * from './base.factory';
   ```

5. ⬜ Write tests for factory
   ```typescript
   // test/factories/factory.spec.ts
   import { describe, it, expect } from 'vitest';
   import { UserFactory } from './user.factory';

   describe('Factory System', () => {
     describe('UserFactory', () => {
       it('should build user without saving', () => {
         const factory = new UserFactory();
         const user = factory.build();
         expect(user.email).toBeDefined();
         expect(user.name).toBeDefined();
       });

       it('should create user with overrides', async () => {
         const factory = new UserFactory();
         const user = await factory.create({ email: 'test@example.com' });
         expect(user.email).toBe('test@example.com');
         expect(user.id).toBeDefined();
       });

       it('should create multiple users', async () => {
         const factory = new UserFactory();
         const users = await factory.createMany(3);
         expect(users).toHaveLength(3);
       });
     });
   });
   ```

**Verification:**
```bash
pnpm test test/factories
# Should pass factory tests
```

**Acceptance Criteria:**
- ✅ Factories can build entities
- ✅ Factories can create entities (save to DB)
- ✅ Factories support overrides
- ✅ Factories support createMany
- ✅ Faker generates realistic data

**Complexity**: High (H)
**Time Estimate**: 4 hours

---

### Task 2.4: Set Up Supertest for HTTP Testing

**Files to Create:**
- `test/helpers/app-test.helper.ts`
- `test/controllers/example.spec.ts`

**Tests First**: Write HTTP test first

**Implementation Steps:**

1. ⬜ Install Supertest
   ```bash
   pnpm add -D supertest @types/supertest
   ```

2. ⬜ Create app test helper
   ```typescript
   // test/helpers/app-test.helper.ts
   import { Test, TestingModule } from '@nestjs/testing';
   import { INestApplication, ValidationPipe } from '@nestjs/common';
   import { AppModule } from '@/app.module';

   export async function createTestApp(): Promise<INestApplication> {
     const moduleFixture: TestingModule = await Test.createTestingModule({
       imports: [AppModule],
     }).compile();

     const app = moduleFixture.createNestApplication();

     // Apply same global pipes as production
     app.useGlobalPipes(
       new ValidationPipe({
         whitelist: true,
         transform: true,
         forbidNonWhitelisted: true,
       })
     );

     await app.init();
     return app;
   }

   export async function closeTestApp(app: INestApplication): Promise<void> {
     await app.close();
   }
   ```

3. ⬜ Create example HTTP test
   ```typescript
   // test/controllers/health.spec.ts
   import { describe, it, expect, beforeAll, afterAll } from 'vitest';
   import request from 'supertest';
   import { INestApplication } from '@nestjs/common';
   import { createTestApp, closeTestApp } from '../helpers/app-test.helper';

   describe('HealthController (HTTP)', () => {
     let app: INestApplication;

     beforeAll(async () => {
       app = await createTestApp();
     });

     afterAll(async () => {
       await closeTestApp(app);
     });

     describe('GET /health', () => {
       it('should return health status', async () => {
         const response = await request(app.getHttpServer())
           .get('/health')
           .expect(200);

         expect(response.body).toHaveProperty('status');
         expect(response.body.status).toBe('ok');
       });
     });

     describe('GET /health/ready', () => {
       it('should return ready status', async () => {
         const response = await request(app.getHttpServer())
           .get('/health/ready')
           .expect(200);

         expect(response.body).toHaveProperty('status');
         expect(response.body.status).toBe('ready');
       });
     });
   });
   ```

4. ⬜ Run HTTP tests
   ```bash
   pnpm test test/controllers
   ```

**Verification:**
```bash
pnpm test test/controllers/health.spec.ts
# Should pass HTTP tests
```

**Acceptance Criteria:**
- ✅ Supertest can make HTTP requests
- ✅ Test app starts and stops cleanly
- ✅ Can test all HTTP methods
- ✅ Response validation works

**Complexity**: Medium (M)
**Time Estimate**: 2 hours

---

### Task 2.5: Configure Coverage Reporting

**Files to Modify:**
- `vitest.config.ts` (already done in 2.1)
- `package.json`

**Tests First**: N/A (reporting task)

**Implementation Steps:**

1. ⬜ Add coverage scripts to package.json
   ```json
   {
     "scripts": {
       "test:cov": "vitest --coverage",
       "test:cov:ui": "vitest --coverage --ui"
     }
   }
   ```

2. ⬜ Create coverage ignore file
   ```
   # .coverageignore
   node_modules/
   dist/
   test/
   **/*.spec.ts
   **/*.test.ts
   **/*.config.ts
   **/index.ts
   src/main.ts
   ```

3. ⬜ Generate coverage report
   ```bash
   pnpm test:cov
   ```

4. ⬜ Verify coverage thresholds
   ```bash
   # Should fail if coverage < 90%
   pnpm test:cov
   ```

**Verification:**
```bash
pnpm test:cov
# Should generate coverage/ directory
# Should show coverage percentages
open coverage/index.html
# Should display HTML coverage report
```

**Acceptance Criteria:**
- ✅ Coverage reports generate
- ✅ HTML report viewable
- ✅ LCOV format for CI
- ✅ Thresholds enforced (90%)

**Complexity**: Small (S)
**Time Estimate**: 1 hour

---

### Task 2.6: Create Test Helpers and Utilities

**Files to Create:**
- `test/helpers/auth.helper.ts`
- `test/helpers/request.helper.ts`
- `test/helpers/assert.helper.ts`

**Tests First**: Write tests that use helpers

**Implementation Steps:**

1. ⬜ Create auth helper (for JWT tokens in tests)
   ```typescript
   // test/helpers/auth.helper.ts
   import * as jwt from 'jsonwebtoken';

   export function generateTestToken(payload: any): string {
     return jwt.sign(payload, process.env.JWT_SECRET || 'test-secret', {
       expiresIn: '1h',
     });
   }

   export function generateTestUserToken(userId: string, role = 'agent'): string {
     return generateTestToken({ userId, role, type: 'access' });
   }

   export function getAuthHeader(token: string): { Authorization: string } {
     return { Authorization: `Bearer ${token}` };
   }
   ```

2. ⬜ Create request helper
   ```typescript
   // test/helpers/request.helper.ts
   import request from 'supertest';
   import { INestApplication } from '@nestjs/common';

   export class TestRequest {
     constructor(private app: INestApplication) {}

     get(url: string) {
       return request(this.app.getHttpServer()).get(url);
     }

     post(url: string, data?: any) {
       return request(this.app.getHttpServer()).post(url).send(data);
     }

     put(url: string, data?: any) {
       return request(this.app.getHttpServer()).put(url).send(data);
     }

     patch(url: string, data?: any) {
       return request(this.app.getHttpServer()).patch(url).send(data);
     }

     delete(url: string) {
       return request(this.app.getHttpServer()).delete(url);
     }

     withAuth(token: string) {
       // Returns a chainable request with auth header
       return this;
     }
   }
   ```

3. ⬜ Create custom assertions
   ```typescript
   // test/helpers/assert.helper.ts
   import { expect } from 'vitest';

   export function assertValidUUID(value: string): void {
     const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
     expect(value).toMatch(uuidRegex);
   }

   export function assertValidEmail(value: string): void {
     const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
     expect(value).toMatch(emailRegex);
   }

   export function assertTimestamp(value: any): void {
     expect(value).toBeDefined();
     expect(new Date(value).toString()).not.toBe('Invalid Date');
   }

   export function assertPaginatedResponse(response: any): void {
     expect(response).toHaveProperty('data');
     expect(response).toHaveProperty('meta');
     expect(response.meta).toHaveProperty('total');
     expect(response.meta).toHaveProperty('page');
     expect(response.meta).toHaveProperty('perPage');
   }
   ```

4. ⬜ Create helper index
   ```typescript
   // test/helpers/index.ts
   export * from './auth.helper';
   export * from './request.helper';
   export * from './assert.helper';
   export * from './app-test.helper';
   ```

**Verification:**
```bash
# Write a test that uses helpers
pnpm test
```

**Acceptance Criteria:**
- ✅ Auth helpers generate valid tokens
- ✅ Request helpers simplify HTTP tests
- ✅ Custom assertions work
- ✅ Helpers are reusable

**Complexity**: Medium (M)
**Time Estimate**: 3 hours

---

### Task 2.7: Set Up CI Pipeline (GitHub Actions)

**Files to Create:**
- `.github/workflows/test.yml`
- `.github/workflows/lint.yml`

**Tests First**: N/A (CI task)

**Implementation Steps:**

1. ⬜ Create test workflow
   ```yaml
   # .github/workflows/test.yml
   name: Test Suite

   on:
     push:
       branches: [main, develop, claude/**]
     pull_request:
       branches: [main, develop]

   jobs:
     test:
       runs-on: ubuntu-latest

       services:
         postgres:
           image: postgres:16
           env:
             POSTGRES_USER: postgres
             POSTGRES_PASSWORD: postgres
             POSTGRES_DB: chatwoot_test
           options: >-
             --health-cmd pg_isready
             --health-interval 10s
             --health-timeout 5s
             --health-retries 5
           ports:
             - 5432:5432

         redis:
           image: redis:7
           options: >-
             --health-cmd "redis-cli ping"
             --health-interval 10s
             --health-timeout 5s
             --health-retries 5
           ports:
             - 6379:6379

       steps:
         - uses: actions/checkout@v4

         - name: Setup Node.js
           uses: actions/setup-node@v4
           with:
             node-version: '23'
             cache: 'pnpm'

         - name: Install pnpm
           run: npm install -g pnpm@10

         - name: Install dependencies
           run: pnpm install --frozen-lockfile

         - name: Run type check
           run: pnpm type-check

         - name: Run tests
           run: pnpm test:cov
           env:
             NODE_ENV: test
             DATABASE_URL: postgresql://postgres:postgres@localhost:5432/chatwoot_test
             REDIS_URL: redis://localhost:6379

         - name: Upload coverage
           uses: codecov/codecov-action@v4
           with:
             files: ./coverage/lcov.info
             flags: typescript

         - name: Check coverage threshold
           run: pnpm test:cov
   ```

2. ⬜ Create lint workflow
   ```yaml
   # .github/workflows/lint.yml
   name: Lint

   on:
     push:
       branches: [main, develop, claude/**]
     pull_request:
       branches: [main, develop]

   jobs:
     lint:
       runs-on: ubuntu-latest

       steps:
         - uses: actions/checkout@v4

         - name: Setup Node.js
           uses: actions/setup-node@v4
           with:
             node-version: '23'
             cache: 'pnpm'

         - name: Install pnpm
           run: npm install -g pnpm@10

         - name: Install dependencies
           run: pnpm install --frozen-lockfile

         - name: Run ESLint
           run: pnpm lint

         - name: Run Prettier check
           run: pnpm format -- --check
   ```

3. ⬜ Test CI locally (if using act)
   ```bash
   act -j test
   ```

**Verification:**
```bash
# Push to GitHub and check Actions tab
git push origin <branch>
# Should see green checkmarks
```

**Acceptance Criteria:**
- ✅ Tests run on every PR
- ✅ Linting runs on every PR
- ✅ Coverage uploaded to Codecov
- ✅ CI passes before merge

**Complexity**: Medium (M)
**Time Estimate**: 2 hours

---

### Task 2.8: Configure Pre-commit Hooks

**Files to Create:**
- `.husky/pre-commit`
- `.husky/pre-push`
- `.lintstagedrc.js`

**Tests First**: N/A (tooling task)

**Implementation Steps:**

1. ⬜ Install Husky and lint-staged
   ```bash
   pnpm add -D husky lint-staged
   npx husky install
   ```

2. ⬜ Create pre-commit hook
   ```bash
   npx husky add .husky/pre-commit "npx lint-staged"
   ```

   ```bash
   # .husky/pre-commit
   #!/usr/bin/env sh
   . "$(dirname -- "$0")/_/husky.sh"

   npx lint-staged
   ```

3. ⬜ Create pre-push hook
   ```bash
   npx husky add .husky/pre-push "pnpm test"
   ```

   ```bash
   # .husky/pre-push
   #!/usr/bin/env sh
   . "$(dirname -- "$0")/_/husky.sh"

   pnpm test
   ```

4. ⬜ Configure lint-staged
   ```javascript
   // .lintstagedrc.js
   module.exports = {
     '*.ts': [
       'eslint --fix',
       'prettier --write',
       () => 'pnpm type-check',
     ],
     '*.{json,md}': ['prettier --write'],
   };
   ```

5. ⬜ Add postinstall script to package.json
   ```json
   {
     "scripts": {
       "prepare": "husky install"
     }
   }
   ```

6. ⬜ Test hooks
   ```bash
   # Make a change and try to commit
   echo "test" >> test-file.ts
   git add test-file.ts
   git commit -m "test"
   # Should run lint-staged
   ```

**Verification:**
```bash
# Try to commit bad code
git commit -m "test"
# Should fail if linting fails

# Try to push with failing tests
git push
# Should fail if tests fail
```

**Acceptance Criteria:**
- ✅ Pre-commit runs linting and formatting
- ✅ Pre-push runs tests
- ✅ Bad commits are blocked
- ✅ Hooks run automatically

**Complexity**: Small (S)
**Time Estimate**: 1 hour

---

## Dependencies

This epic depends on:
- ✅ Epic 01: Infrastructure Setup (database, Redis, config)

This epic enables:
- All subsequent epics (provides testing framework)

---

## Rollback Plan

**If Epic 02 needs to be abandoned:**

1. Remove test dependencies from package.json
2. Delete test/ directory
3. Delete CI workflows
4. Remove Husky hooks
5. Continue using Epic 01 infrastructure

**Time to Rollback**: < 5 minutes

---

## Documentation Checklist

- ⬜ TESTING.md (testing guide)
- ⬜ FACTORIES.md (factory usage)
- ⬜ CI.md (CI/CD documentation)
- ⬜ Update CONTRIBUTING.md (TDD process)

---

## Notes

- **TDD is mandatory** for all subsequent epics
- Test coverage must be ≥90%
- All tests must pass before merging
- Factories will grow as models are added in Epic 03

---

**Epic Status**: 🟡 Ready to Start (after Epic 01)
**Estimated Duration**: 1-2 weeks
**Next Epic**: Epic 03 - Database Models & Migrations
