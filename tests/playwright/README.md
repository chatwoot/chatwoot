# Chatwoot E2E Testing

End-to-end testing framework for Chatwoot using Component Object Model pattern.

## Setup

```bash
# Install dependencies
pnpm install

# Install Playwright browsers
npx playwright install

# Configure environment
cp .env.example .env
```

Edit `.env` with your Chatwoot instance URL and credentials.

## Usage

```bash
# Run all tests
pnpm run playwright:run

# Run tests in UI mode
pnpm run playwright:open

# Lint tests and page objects
pnpm run lint

# Generate test code
pnpm run playwright:codegen
```

## Project Structure

```
tests/playwright/
├── components/
│   └── ui/               # UI page objects
├── tests/
│   └── e2e/
│       └── ui/           # UI tests
```

## Documentation

See [DOCS.md](./DOCS.md) for complete testing guide including patterns, conventions, and troubleshooting.

## Configuration

See `.env.example` for the full list of variables.
