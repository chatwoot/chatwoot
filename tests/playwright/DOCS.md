# Chatwoot E2E Testing - Documentation

Complete guide for writing and maintaining E2E tests for Chatwoot.

---

## Overview

End-to-end testing suite for Chatwoot built with Playwright and TypeScript using the Component Object Model (COM) pattern.

---

## Architecture

```
tests/playwright/
├── components/
│   ├── api/              # API interaction (auth.component.ts, inbox.component.ts ...)
│   └── ui/               # UI page objects (login.component.ts, agent-page.component.ts ...)
├── tests/e2e/            # Test specs (api/ and ui/)
├── utils/                # Shared utilities (fixture.ts, test-data.ts, db.ts)
├── response-schemas/     # API response schemas for validation
├── fixtures/             # Test fixtures
├── helpers/              # Helper functions
└── playwright.config.ts
```

---

## Configuration

All configuration managed through `.env` file. Copy `.env.example` to `.env`:

```
BASE_URL=http://localhost:3000
TEST_USER_EMAIL=admin@chatwoot.com
TEST_USER_PASSWORD="Password123@#"
ACCOUNT_ID=1

# Add additional variables as needed by specific test suites
# VARIABLE_NAME=value
```

> **Note:** `npx playwright install` is required after `pnpm install` to download browser binaries.

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
- Ensure Chatwoot is running at `BASE_URL`
- Increase timeout: `{ timeout: 60000 }`

**Element not found:**
- Use `page.pause()` to inspect
- Check for timing issues
