# Testing, CI/CD, and Security Standards

## Testing Strategy

### Test-Driven Development (TDD) Mandate

**Every task must follow this process:**

1. **Read Original Code** (Ruby + RSpec)
2. **Write TypeScript Tests First** (Red)
3. **Implement TypeScript Code** (Green)
4. **Refactor** (Refactor)
5. **Verify Feature Parity**
6. **Commit**

**No exceptions.** Code without tests will not be merged.

---

## Test Pyramid

### Current (RSpec)

```
           /\
          /  \  618 test files
         / E2E \
        /--------\
       /  Inte-  \
      /  gration  \
     /--------------\
    /  Controllers  \
   /------------------\
  /   Models/Services  \
 /------------------------\
```

### Target (Vitest)

```
           /\
          /  \  ≥618 test files
         / E2E \
        /--------\
       /  Inte-  \
      /  gration  \
     /--------------\
    /  Controllers  \
   /------------------\
  /   Models/Services  \
 /------------------------\
```

**Coverage Target:** ≥90% (match or exceed Rails)

---

## Testing Tools & Setup

### Primary Framework: Vitest

**Why Vitest:**
- Native TypeScript support
- Fast (Vite-powered)
- Jest-compatible API
- ESM support
- Watch mode
- Coverage built-in

**Configuration:**
```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    setupFiles: ['./test/setup.ts'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html', 'lcov'],
      exclude: [
        'node_modules/',
        'test/',
        '**/*.spec.ts',
        '**/*.test.ts',
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
  },
});
```

### Integration Testing: Supertest

**Why Supertest:**
- HTTP testing
- Works with NestJS/Express
- Fluent API
- Well-maintained

**Example:**
```typescript
import request from 'supertest';
import { INestApplication } from '@nestjs/common';

describe('ConversationsController', () => {
  let app: INestApplication;

  beforeAll(async () => {
    app = await createTestApp();
  });

  it('GET /api/v1/conversations', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/v1/conversations')
      .set('Authorization', 'Bearer <token>')
      .expect(200);

    expect(response.body).toHaveProperty('data');
    expect(response.body.data).toBeInstanceOf(Array);
  });
});
```

### E2E Testing: Playwright (optional)

**For critical user flows:**
- Authentication
- Message sending
- Channel integration
- Widget functionality

---

## Test Data Management

### Factory Pattern (like FactoryBot)

**Tool:** Custom factory or `@faker-js/faker`

**Example:**
```typescript
// test/factories/user.factory.ts
import { faker } from '@faker-js/faker';
import { User } from '@/models/User';

export class UserFactory {
  static build(overrides?: Partial<User>): User {
    return {
      id: faker.string.uuid(),
      email: faker.internet.email(),
      name: faker.person.fullName(),
      password: 'password123',
      accountId: faker.string.uuid(),
      role: 'agent',
      createdAt: new Date(),
      updatedAt: new Date(),
      ...overrides,
    };
  }

  static async create(overrides?: Partial<User>): Promise<User> {
    const user = this.build(overrides);
    return await userRepository.save(user);
  }

  static async createMany(count: number, overrides?: Partial<User>): Promise<User[]> {
    const users = Array.from({ length: count }, () => this.build(overrides));
    return await userRepository.save(users);
  }
}
```

### Database Test Setup

**Strategy:** Isolated test database

```typescript
// test/setup.ts
import { DataSource } from 'typeorm';

let testDataSource: DataSource;

export async function setupTestDatabase() {
  testDataSource = new DataSource({
    type: 'postgres',
    host: process.env.TEST_DB_HOST || 'localhost',
    port: parseInt(process.env.TEST_DB_PORT || '5432'),
    username: process.env.TEST_DB_USER || 'postgres',
    password: process.env.TEST_DB_PASSWORD || 'postgres',
    database: process.env.TEST_DB_NAME || 'chatwoot_test',
    entities: ['src/**/*.entity.ts'],
    synchronize: true, // For tests only
    dropSchema: true, // Clean slate each run
  });

  await testDataSource.initialize();
}

export async function teardownTestDatabase() {
  await testDataSource.destroy();
}

beforeAll(async () => {
  await setupTestDatabase();
});

afterAll(async () => {
  await teardownTestDatabase();
});

beforeEach(async () => {
  // Clean database before each test
  await testDataSource.synchronize(true);
});
```

---

## Test Types & Patterns

### 1. Model Tests

**Equivalent to:** RSpec model specs

**What to test:**
- Validations
- Associations
- Scopes
- Instance methods
- Class methods
- Hooks (callbacks)

**Example:**
```typescript
// src/models/User.spec.ts
import { User } from './User';
import { UserFactory } from '@test/factories/user.factory';

describe('User Model', () => {
  describe('validations', () => {
    it('requires email', async () => {
      const user = UserFactory.build({ email: '' });
      await expect(user.save()).rejects.toThrow();
    });

    it('validates email format', async () => {
      const user = UserFactory.build({ email: 'invalid' });
      await expect(user.save()).rejects.toThrow();
    });

    it('enforces unique email', async () => {
      await UserFactory.create({ email: 'test@example.com' });
      const duplicate = UserFactory.build({ email: 'test@example.com' });
      await expect(duplicate.save()).rejects.toThrow();
    });
  });

  describe('associations', () => {
    it('belongs to account', async () => {
      const user = await UserFactory.create();
      expect(user.account).toBeDefined();
    });

    it('has many conversations', async () => {
      const user = await UserFactory.create();
      await ConversationFactory.create({ assigneeId: user.id });
      const conversations = await user.conversations();
      expect(conversations).toHaveLength(1);
    });
  });

  describe('methods', () => {
    it('generates JWT token', async () => {
      const user = await UserFactory.create();
      const token = user.generateToken();
      expect(token).toMatch(/^[\w-]+\.[\w-]+\.[\w-]+$/);
    });
  });
});
```

### 2. Service Tests

**Equivalent to:** RSpec service specs

**What to test:**
- Business logic
- Error handling
- Side effects
- External API calls (mocked)

**Example:**
```typescript
// src/services/ConversationService.spec.ts
import { ConversationService } from './ConversationService';
import { ConversationFactory } from '@test/factories/conversation.factory';

describe('ConversationService', () => {
  let service: ConversationService;

  beforeEach(() => {
    service = new ConversationService();
  });

  describe('assignAgent', () => {
    it('assigns agent to conversation', async () => {
      const conversation = await ConversationFactory.create({ status: 'open' });
      const agent = await UserFactory.create({ role: 'agent' });

      const result = await service.assignAgent(conversation.id, agent.id);

      expect(result.assigneeId).toBe(agent.id);
      expect(result.status).toBe('open');
    });

    it('throws error if conversation not found', async () => {
      await expect(
        service.assignAgent('invalid-id', 'agent-id')
      ).rejects.toThrow('Conversation not found');
    });
  });
});
```

### 3. Controller Tests

**Equivalent to:** RSpec request specs

**What to test:**
- HTTP endpoints
- Request/response format
- Authentication/authorization
- Validation errors
- Status codes

**Example:**
```typescript
// src/controllers/ConversationsController.spec.ts
import request from 'supertest';
import { app } from '@/app';
import { UserFactory } from '@test/factories/user.factory';

describe('ConversationsController', () => {
  let authToken: string;

  beforeEach(async () => {
    const user = await UserFactory.create();
    authToken = user.generateToken();
  });

  describe('GET /api/v1/conversations', () => {
    it('returns conversations for authenticated user', async () => {
      await ConversationFactory.createMany(3);

      const response = await request(app)
        .get('/api/v1/conversations')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data).toHaveLength(3);
      expect(response.body.data[0]).toHaveProperty('id');
      expect(response.body.data[0]).toHaveProperty('status');
    });

    it('returns 401 without authentication', async () => {
      await request(app)
        .get('/api/v1/conversations')
        .expect(401);
    });
  });

  describe('POST /api/v1/conversations', () => {
    it('creates conversation', async () => {
      const inbox = await InboxFactory.create();
      const contact = await ContactFactory.create();

      const response = await request(app)
        .post('/api/v1/conversations')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          inbox_id: inbox.id,
          contact_id: contact.id,
        })
        .expect(201);

      expect(response.body).toHaveProperty('id');
    });

    it('validates required fields', async () => {
      await request(app)
        .post('/api/v1/conversations')
        .set('Authorization', `Bearer ${authToken}`)
        .send({})
        .expect(422);
    });
  });
});
```

### 4. Integration Tests

**What to test:**
- End-to-end flows
- Multiple services working together
- Database transactions
- Background jobs triggering

**Example:**
```typescript
// test/integration/message-flow.spec.ts
describe('Message Flow Integration', () => {
  it('creates message and triggers notifications', async () => {
    const agent = await UserFactory.create({ role: 'agent' });
    const conversation = await ConversationFactory.create({ assigneeId: agent.id });
    const contact = await ContactFactory.create();

    // Create message
    const response = await request(app)
      .post(`/api/v1/conversations/${conversation.id}/messages`)
      .set('Authorization', `Bearer ${agent.generateToken()}`)
      .send({
        content: 'Hello!',
        message_type: 'outgoing',
      })
      .expect(201);

    const message = response.body;

    // Verify message created
    expect(message.content).toBe('Hello!');

    // Verify background job enqueued
    const jobs = await notificationQueue.getJobs();
    expect(jobs).toHaveLength(1);
    expect(jobs[0].data.messageId).toBe(message.id);

    // Process job
    await worker.process();

    // Verify notification sent
    const notifications = await Notification.find({ messageId: message.id });
    expect(notifications).toHaveLength(1);
  });
});
```

---

## Continuous Integration (CI)

### GitHub Actions Workflow

```yaml
# .github/workflows/test.yml
name: Test Suite

on:
  push:
    branches: [main, develop]
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

      - name: Run linter
        run: pnpm lint

      - name: Run type check
        run: pnpm type-check

      - name: Run tests
        run: pnpm test:coverage
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
        run: pnpm test:coverage --passWithNoTests
```

### Pre-commit Hooks

```json
// package.json
{
  "husky": {
    "hooks": {
      "pre-commit": "lint-staged",
      "pre-push": "pnpm test"
    }
  },
  "lint-staged": {
    "*.ts": [
      "eslint --fix",
      "prettier --write",
      "vitest related --run"
    ]
  }
}
```

---

## Code Quality Standards

### ESLint Configuration

```typescript
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
    '@typescript-eslint/no-unused-vars': 'error',
    'no-console': 'warn',
  },
};
```

### TypeScript Configuration

```json
// tsconfig.json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "commonjs",
    "lib": ["ES2022"],
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "experimentalDecorators": true,
    "emitDecoratorMetadata": true,
    "baseUrl": "./",
    "paths": {
      "@/*": ["src/*"],
      "@test/*": ["test/*"]
    }
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "test"]
}
```

---

## Security Standards

### 1. Authentication Security

**Requirements:**
- Bcrypt for password hashing (min 12 rounds)
- JWT with short expiration (15 min access, 7 day refresh)
- Token rotation on refresh
- Secure cookie flags (HttpOnly, Secure, SameSite)
- Rate limiting on auth endpoints

**Implementation:**
```typescript
import * as bcrypt from 'bcrypt';
import * as jwt from 'jsonwebtoken';

const SALT_ROUNDS = 12;
const ACCESS_TOKEN_EXPIRY = '15m';
const REFRESH_TOKEN_EXPIRY = '7d';

export async function hashPassword(password: string): Promise<string> {
  return bcrypt.hash(password, SALT_ROUNDS);
}

export async function verifyPassword(password: string, hash: string): Promise<boolean> {
  return bcrypt.compare(password, hash);
}

export function generateAccessToken(userId: string): string {
  return jwt.sign({ userId, type: 'access' }, process.env.JWT_SECRET, {
    expiresIn: ACCESS_TOKEN_EXPIRY,
  });
}
```

### 2. Input Validation

**Tool:** class-validator + class-transformer

**Example:**
```typescript
import { IsEmail, IsNotEmpty, MinLength, MaxLength } from 'class-validator';

export class CreateUserDto {
  @IsEmail()
  @IsNotEmpty()
  email: string;

  @IsNotEmpty()
  @MinLength(8)
  @MaxLength(128)
  password: string;

  @IsNotEmpty()
  @MaxLength(255)
  name: string;
}
```

### 3. SQL Injection Prevention

**Strategy:** Use ORM (TypeORM) exclusively

**Never:**
```typescript
// DON'T DO THIS
const user = await query(`SELECT * FROM users WHERE email = '${email}'`);
```

**Always:**
```typescript
// DO THIS
const user = await userRepository.findOne({ where: { email } });
```

### 4. XSS Prevention

**Tool:** DOMPurify (frontend) + sanitization (backend)

```typescript
import { sanitize } from '@/utils/sanitize';

export async function createMessage(content: string): Promise<Message> {
  const sanitizedContent = sanitize(content);
  return messageRepository.save({ content: sanitizedContent });
}
```

### 5. Rate Limiting

**Tool:** @nestjs/throttler

```typescript
import { ThrottlerModule } from '@nestjs/throttler';

@Module({
  imports: [
    ThrottlerModule.forRoot({
      ttl: 60,
      limit: 10,
    }),
  ],
})
export class AppModule {}
```

### 6. CSRF Protection

**Strategy:** SameSite cookies + CSRF tokens for non-GET requests

### 7. Secrets Management

**Never commit:**
- API keys
- Database credentials
- JWT secrets
- OAuth credentials

**Use:**
- Environment variables
- AWS Secrets Manager / HashiCorp Vault (production)

---

## Performance Standards

### API Response Times

| Endpoint Type | Target | Max |
|--------------|--------|-----|
| Simple GET | <50ms | 100ms |
| Complex GET | <200ms | 500ms |
| POST/PUT | <100ms | 300ms |
| DELETE | <50ms | 150ms |

### Background Job Processing

| Job Type | Target | SLA |
|----------|--------|-----|
| Real-time notifications | <1s | 5s |
| Email delivery | <5s | 30s |
| Report generation | <30s | 5min |
| Data import | <5min | 30min |

### Database Queries

- **N+1 queries**: Not allowed (use eager loading)
- **Index all foreign keys**
- **Query timeout**: 5s max

---

## Monitoring & Observability

### Logging

**Tool:** Winston or Pino

```typescript
import { Logger } from '@nestjs/common';

const logger = new Logger('ConversationService');

logger.log('Conversation created', { conversationId });
logger.error('Failed to assign agent', { error, conversationId });
logger.warn('High queue backlog', { queueSize });
```

### Metrics

**Tool:** Prometheus + Grafana

**Key Metrics:**
- Request rate (req/s)
- Error rate (%)
- Response time (p50, p95, p99)
- Database connection pool
- Queue depth
- Cache hit rate

### Error Tracking

**Tool:** Sentry

```typescript
import * as Sentry from '@sentry/node';

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  environment: process.env.NODE_ENV,
});

try {
  await service.performAction();
} catch (error) {
  Sentry.captureException(error);
  throw error;
}
```

---

## Documentation Standards

### Code Documentation

**Use JSDoc:**
```typescript
/**
 * Assigns an agent to a conversation
 * @param conversationId - The conversation ID
 * @param agentId - The agent ID to assign
 * @returns The updated conversation
 * @throws {NotFoundError} If conversation or agent not found
 * @throws {UnauthorizedError} If agent lacks permissions
 */
export async function assignAgent(
  conversationId: string,
  agentId: string
): Promise<Conversation> {
  // Implementation
}
```

### API Documentation

**Tool:** Swagger (OpenAPI)

**Auto-generated** from NestJS decorators

---

## Definition of Done (DoD)

**A task is ONLY complete when:**

- ✅ Tests written (TDD: Red → Green → Refactor)
- ✅ All tests passing
- ✅ Code coverage ≥90%
- ✅ ESLint passing (zero errors, zero warnings)
- ✅ TypeScript strict mode passing
- ✅ Code reviewed
- ✅ Documentation updated
- ✅ Feature flag configured (if applicable)
- ✅ Committed with clear message

---

**Status**: ✅ Standards Defined
**Next**: Apply to all epic tasks
