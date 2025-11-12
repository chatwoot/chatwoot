# Chatwoot TypeScript/NestJS API

Modern TypeScript/NestJS implementation of the Chatwoot API - migrated from Ruby on Rails.

## 🚀 Features

- **NestJS Framework** - Production-ready TypeScript framework
- **TypeScript Strict Mode** - Full type safety
- **PostgreSQL** - Primary database with TypeORM
- **Redis** - Caching and background jobs (BullMQ)
- **Winston Logging** - Structured logging with daily rotation
- **Health Checks** - Comprehensive health monitoring endpoints
- **Global Error Handling** - Centralized exception handling
- **CORS Support** - Configurable cross-origin resource sharing
- **Validation** - Automatic request validation with class-validator

## 📋 Prerequisites

- Node.js >= 18.x
- pnpm >= 8.x
- PostgreSQL >= 14.x
- Redis >= 6.x

## 🛠️ Installation

### Quick Start

```bash
# Clone the repository (or use existing)
cd chatwoot-typescript

# Run setup script
pnpm run setup:dev
```

This will:
- Create `.env` file from `.env.example`
- Install dependencies
- Create necessary directories
- Build the project

### Manual Setup

```bash
# Install dependencies
pnpm install

# Copy environment file
cp .env.example .env

# Update .env with your configuration

# Run migrations
pnpm migration:run

# Build the project
pnpm build
```

## 🔧 Development

```bash
# Start development server (with hot reload)
pnpm start:dev

# Start in debug mode
pnpm start:debug

# Build for production
pnpm build

# Start production server
pnpm start:prod
```

## 🧪 Testing

```bash
# Run tests
pnpm test

# Run tests in watch mode
pnpm test:watch

# Run tests with coverage
pnpm test:cov

# Run e2e tests
pnpm test:e2e
```

## 🗄️ Database

### Migrations

```bash
# Generate a new migration
pnpm migration:generate src/database/migrations/MigrationName

# Create an empty migration
pnpm migration:create src/database/migrations/MigrationName

# Run migrations
pnpm migration:run

# Revert last migration
pnpm migration:revert

# Reset database (WARNING: destructive!)
pnpm db:reset
```

## 🔍 Code Quality

```bash
# Lint code
pnpm lint

# Fix linting issues
pnpm lint:fix

# Format code
pnpm format
```

## 🏥 Health Checks

The application provides three health check endpoints:

- `GET /health` - Complete health check (database, Redis, memory, disk)
- `GET /health/live` - Liveness probe (app is running)
- `GET /health/ready` - Readiness probe (app can serve traffic)

## 📁 Project Structure

```
chatwoot-typescript/
├── src/
│   ├── common/           # Shared utilities, decorators, filters, etc.
│   ├── config/           # Configuration modules
│   ├── controllers/      # HTTP controllers
│   ├── database/         # Migrations and seeders
│   ├── integrations/     # Third-party integrations
│   ├── jobs/             # Background jobs
│   ├── listeners/        # Event listeners
│   ├── models/           # TypeORM entities
│   ├── modules/          # Feature modules
│   └── services/         # Business logic
├── scripts/              # Development scripts
├── logs/                 # Application logs
└── storage/              # File storage
```

See [PROJECT_STRUCTURE.md](./PROJECT_STRUCTURE.md) for detailed documentation.

## 🔐 Environment Variables

Copy `.env.example` to `.env` and configure:

### Application
- `NODE_ENV` - Environment (development, production, test)
- `PORT` - Server port (default: 3000)
- `APP_NAME` - Application name
- `FRONTEND_URL` - Frontend application URL
- `API_VERSION` - API version

### Database
- `DATABASE_HOST` - PostgreSQL host
- `DATABASE_PORT` - PostgreSQL port
- `DATABASE_NAME` - Database name
- `DATABASE_USERNAME` - Database user
- `DATABASE_PASSWORD` - Database password

### Redis
- `REDIS_HOST` - Redis host
- `REDIS_PORT` - Redis port
- `REDIS_PASSWORD` - Redis password (optional)
- `REDIS_DB` - Redis database number

### Security
- `JWT_SECRET` - JWT secret key
- `SESSION_SECRET` - Session secret key
- `ENCRYPTION_KEY` - Encryption key (32 characters)

See `.env.example` for all available options.

## 🐳 Docker Support

```bash
# Coming soon
```

## 📊 Monitoring

- **Logs**: Check `logs/` directory for application logs
- **Health**: Visit `http://localhost:3000/health` for health status
- **Metrics**: Integration with monitoring tools (coming soon)

## 🤝 Contributing

1. Create a feature branch
2. Make your changes
3. Run tests and linting
4. Submit a pull request

### Code Style

- Follow TypeScript strict mode
- Use ESLint and Prettier
- Write meaningful commit messages
- Add tests for new features

## 📚 Documentation

- [Migration Plan](/home/user/chatwoot/migration-plan/README.md)
- [Project Structure](./PROJECT_STRUCTURE.md)
- [API Documentation](./docs/api.md) (coming soon)

## 🛠️ Useful Scripts

```bash
# Check development environment
pnpm check:env

# Setup development environment
pnpm setup:dev

# Reset database (WARNING: destructive!)
pnpm db:reset
```

## 📝 License

MIT

## 🔗 Related Projects

- [Chatwoot (Rails)](https://github.com/chatwoot/chatwoot) - Original Ruby on Rails application
- [Chatwoot Frontend](https://github.com/chatwoot/chatwoot) - Vue.js frontend

## 📧 Support

For questions and support, please refer to the main Chatwoot repository.
