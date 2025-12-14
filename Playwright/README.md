# Chatwoot E2E Testing

End-to-end testing framework for Chatwoot using Component Object Model pattern.

## Setup

```bash
# Install dependencies
npm install

# Configure environment
cp .env.example .env
```

Edit `.env` with your Chatwoot instance URL and credentials.

## Usage

```bash
# Run all tests
npm run playwright:run

# Run tests in UI mode
npm run playwright:open

# Generate test code
npm run playwright:codegen
```

## Project Structure

```
Playwright/
├── components/
│   ├── api/              # API interaction components
│   └── ui/               # UI page objects
├── tests/
│   └── e2e/
│       ├── api/          # Pure API tests
│       └── ui/           # UI tests
├── utils/                # Shared utilities and helpers
├── response-schemas/     # API response schemas for validation
├── fixtures/             # Test fixtures
└── helpers/              # Helper functions
```

## Documentation

See [DOCS.md](./DOCS.md) for complete testing guide including patterns, conventions, and troubleshooting.

## Configuration

Required variables in `.env`:

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

See `.env.example` for the template.
