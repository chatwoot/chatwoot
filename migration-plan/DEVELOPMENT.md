# Development Guide - Getting Started

## Prerequisites

### Required Software
- **Node.js** 23.x
- **pnpm** 10.x  
- **PostgreSQL** 16
- **Redis** 7
- **Git**

### Knowledge Requirements
- TypeScript fundamentals
- NestJS basics
- TypeORM/Prisma
- Understanding of Rails (to read original code)

---

## Initial Setup

### 1. Clone Repository

```bash
git clone https://github.com/your-org/chatwoot-typescript.git
cd chatwoot-typescript
```

### 2. Install Dependencies

```bash
pnpm install
```

### 3. Environment Configuration

```bash
cp .env.example .env
```

Edit `.env` with your local settings:
```bash
NODE_ENV=development
PORT=3000

DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_USER=postgres
DATABASE_PASSWORD=postgres
DATABASE_NAME=chatwoot_development
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/chatwoot_development

REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_URL=redis://localhost:6379

JWT_SECRET=your-secret-key-for-dev
```

### 4. Database Setup

```bash
# Create database
createdb chatwoot_development

# Run migrations
pnpm migration:run

# Seed data (optional)
pnpm seed
```

### 5. Start Development Server

```bash
pnpm start:dev
```

Server runs on `http://localhost:3000`

### 6. Verify Setup

```bash
curl http://localhost:3000/health
# Should return: {"status":"ok", ...}
```

---

## Development Workflow

### Running the Application

```bash
# Development mode (with hot reload)
pnpm start:dev

# Debug mode
pnpm start:debug

# Production mode
pnpm start:prod
```

### Running Tests

```bash
# Run all tests
pnpm test

# Watch mode
pnpm test:watch

# Coverage
pnpm test:cov

# Specific test file
pnpm test src/models/user.entity.spec.ts
```

### Linting & Formatting

```bash
# Run ESLint
pnpm lint

# Fix ESLint issues
pnpm lint:fix

# Format code with Prettier
pnpm format
```

### Database Operations

```bash
# Generate migration
pnpm migration:generate src/database/migrations/AddUserRole

# Run migrations
pnpm migration:run

# Revert last migration
pnpm migration:revert

# Show migrations
pnpm migration:show
```

### Type Checking

```bash
# Check types
pnpm type-check

# Watch mode
pnpm type-check --watch
```

---

## Project Structure

```
chatwoot-typescript/
├── src/
│   ├── common/          # Shared utilities
│   ├── config/          # Configuration
│   ├── models/          # TypeORM entities
│   ├── controllers/     # HTTP controllers
│   ├── services/        # Business logic
│   ├── jobs/            # Background jobs
│   ├── integrations/    # Third-party integrations
│   ├── modules/         # Feature modules
│   ├── database/        # Migrations, seeders
│   └── main.ts          # Application entry point
├── test/                # Test utilities
├── migration-plan/      # Migration documentation
├── package.json
├── tsconfig.json
└── .env
```

---

## Common Commands

| Command | Description |
|---------|-------------|
| `pnpm start:dev` | Start dev server with hot reload |
| `pnpm test` | Run all tests |
| `pnpm test:watch` | Run tests in watch mode |
| `pnpm test:cov` | Run tests with coverage |
| `pnpm lint` | Run ESLint |
| `pnpm lint:fix` | Fix ESLint issues |
| `pnpm format` | Format code with Prettier |
| `pnpm type-check` | Check TypeScript types |
| `pnpm migration:run` | Run database migrations |
| `pnpm migration:generate` | Generate new migration |
| `pnpm build` | Build for production |

---

## IDE Setup

### VS Code (Recommended)

**Extensions:**
- ESLint
- Prettier
- TypeScript Vue Plugin
- Jest Runner
- GitLens

**Settings (`.vscode/settings.json`):**
```json
{
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true
  },
  "typescript.tsdk": "node_modules/typescript/lib"
}
```

---

## Debugging

### VS Code Debug Configuration

Create `.vscode/launch.json`:
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "node",
      "request": "launch",
      "name": "Debug NestJS",
      "runtimeExecutable": "pnpm",
      "runtimeArgs": ["start:debug"],
      "console": "integratedTerminal",
      "restart": true,
      "protocol": "inspector",
      "skipFiles": ["<node_internals>/**"]
    }
  ]
}
```

### Debugging Tests

```bash
# Debug specific test
node --inspect-brk node_modules/.bin/vitest src/models/user.entity.spec.ts
```

---

## Troubleshooting

### Database Connection Issues

```bash
# Check PostgreSQL is running
pg_isready

# Check connection
psql -U postgres -h localhost
```

### Redis Connection Issues

```bash
# Check Redis is running
redis-cli ping
# Should return: PONG
```

### Port Already in Use

```bash
# Find process on port 3000
lsof -i :3000

# Kill process
kill -9 <PID>
```

### Module Not Found

```bash
# Clear node_modules and reinstall
rm -rf node_modules pnpm-lock.yaml
pnpm install
```

### TypeScript Errors

```bash
# Clean build
rm -rf dist
pnpm build
```

---

## Next Steps

1. Read [CONTRIBUTING.md](./CONTRIBUTING.md) for development workflow
2. Read [GLOSSARY.md](./GLOSSARY.md) for Rails ↔ TypeScript mapping
3. Pick a task from [progress-tracker.md](./progress-tracker.md)
4. Read the relevant epic plan
5. Start coding with TDD!

---

**Need Help?** Check [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) or ask the team.
