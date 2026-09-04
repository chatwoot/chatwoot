# Chatwoot E2E Testing - Documentation

Complete guide for writing and maintaining E2E tests for Chatwoot.

---

## Overview

End-to-end testing suite for Chatwoot built with Playwright and TypeScript using the Component Object Model (COM) pattern.

---

## Architecture

### Folder Structure

```
Playwright/
├── .github/
│   ├── workflows/
│   │   └── playwright.yml
│   └── playwright-docker-compose.yaml
│
├── components/
│   ├── api/
│   │   ├── auth.component.ts
│   │   ├── agent.component.ts
│   │   ├── agent-onboarding.component.ts
│   │   ├── inbox.component.ts
│   │   ├── conversation.component.ts
│   │   ├── publicInbox.component.ts
│   │   ├── profile.component.ts
│   │   └── index.ts
│   │
│   └── ui/
│       ├── login.component.ts
│       ├── agent-page.component.ts
│       ├── add-agent-modal.component.ts
│       ├── user-menu.component.ts
│       ├── password-reset.component.ts
│       ├── settings-inbox-page.component.ts
│       ├── channel-selector.component.ts
│       ├── api-channel-form.component.ts
│       ├── add-agents-form.component.ts
│       ├── finish-setup.component.ts
│       └── index.ts
│
├── tests/
│   └── e2e/
│       ├── api/
│       │   └── agent-onboarding-api.spec.ts
│       └── ui/
│           ├── login-flow-ui-validation.spec.ts
│           ├── agent-onboarding-flow-ui-validation.spec.ts
│           ├── inbox-creation-flow.spec.ts
│           └── realtime-messaging.spec.ts
│
├── utils/
│   ├── fixture.ts
│   ├── request-handler.ts
│   ├── logger.ts
│   ├── test-data.ts
│   ├── schema-validator.ts
│   ├── cleanup.ts
│   └── db.ts
│
├── fixtures/
│   └── auth.fixture.ts
│
├── helpers/
│   ├── get-auth-headers.ts
│   └── index.ts
│
├── response-schemas/
│   ├── agent/
│   ├── auth/
│   ├── conversation/
│   ├── inbox/
│   └── publicInbox/
│
├── playwright.config.ts
├── tsconfig.json
├── package.json
├── .env.example
└── DOCS.md
```

---

## Test Structure

```typescript
import { expect, test } from '@utils/fixture';
import { fake } from '@utils/test-data';

test.describe('Feature Name', () => {
  test.beforeAll(async ({ api }) => {
    // Create test data
  });

  test.afterAll(async ({ api }) => {
    // Clean up test data
  });

  test('should do something', async ({ page, api }) => {
    const testData = fake.agent();
    const result = await someAction();
    expect(result).toBeTruthy();
  });
});
```

---

## Configuration

All configuration managed through `.env` file. Copy `.env.example` to `.env`:

```json
{
  "baseUrl": "http://localhost:3000",
  "apiBaseUrl": "http://localhost:3000",
  "email": "admin@chatwoot.com",
  "password": "Password123@#",
  "dbUser": "postgres",
  "dbPassword": "postgres",
  "dbHost": "127.0.0.1",
  "dbPort": "5432",
  "dbName": "chatwoot",
  "dbToken": "your_encrypted_token_here",
  "urlToken": "your_plain_token_here"
}
```

---

## Testing Patterns

### API Testing

```typescript
test('API operation', async ({ api }) => {
  const authHeaders = await authComponent.login(email, password);
  const result = await component.create(api, authHeaders, data);
  expect(result.id).toBeTruthy();
});
```

### UI Testing

```typescript
test('UI interaction', async ({ page }) => {
  const loginComponent = new Login(page);
  await loginComponent.login(email, password);
  await expect(page.getByText('Success')).toBeVisible();
});
```

### Hybrid Pattern

```typescript
test('UI with API setup', async ({ page, api }) => {
  // Fast: Create test data via API
  const inbox = await inboxComponent.createApiInbox(api, authHeaders, data);

  // Test UI interactions
  await page.goto(`/app/accounts/2/inbox/${inbox.id}`);
  await expect(page.getByText(inbox.name)).toBeVisible();
});
```

---

## Request Handler

```typescript
const data = await api
  .path('/api/v1/accounts/2/agents')
  .headers(authHeaders)
  .body({ name: 'John', email: 'john@test.com' })
  .logs(true)
  .postRequest(200);
```

**Methods:** `getRequest()`, `postRequest()`, `putRequest()`, `deleteRequest()`

---

## Test Data Generation

```typescript
import { fake } from '@utils/test-data';

const agent = fake.agent({ role: 'agent' });
const inboxName = fake.inboxName();
```

**Available:** `fake.fullName`, `fake.email`, `fake.phoneNumber`, `fake.password`, `fake.agent()`, `fake.inboxName()`

---

## Schema Validation

```typescript
import { validateSchema } from '@utils/schema-validator';

const agent = await agentComponent.create(api, authHeaders, data);
await validateSchema('agent', 'create_agent', agent);
```

**Generate schemas:**
```bash
GENERATE_SCHEMAS=true npm run playwright:run tests/e2e/api/agent-onboarding-api.spec.ts
```

---

## Fixtures

```typescript
import { test } from '@utils/fixture';

test('with fixtures', async ({ api, logger }) => {
  // api and logger available
});
```

---

## Best Practices

**Do:**
- Use existing components
- Use `fake` for test data
- Use semantic selectors (`getByRole`, `getByLabel`)
- Clean up test data in `afterAll`
- Validate API schemas

**Don't:**
- Use CSS selectors
- Hardcode wait times
- Skip cleanup
- Test implementation details
- Commit sensitive data

---

## Troubleshooting

**Authentication errors:**
- Verify `.env` credentials match Chatwoot
- Check for rate limiting (429 errors)

**Database errors:**
- Verify database is running
- Check credentials in `.env`

**Timeout errors:**
- Ensure Chatwoot is running at `baseUrl`
- Increase timeout: `{ timeout: 60000 }`

**Element not found:**
- Use `page.pause()` to inspect
- Check for timing issues

**Schema validation errors:**
- Regenerate schemas if API changed
- Review schema file in `response-schemas/`

---

## Conventions

- Use descriptive names
- Use TypeScript types, avoid `any`
- Always use async/await
- Generate test data via `fake`
- Run ESLint before committing
- Add schema validation to API tests
