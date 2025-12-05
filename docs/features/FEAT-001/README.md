# Evolution API WhatsApp Integration

> **Status**: ✅ Production-Ready
> **Version**: 2.0
> **Last Updated**: 2025-09-20

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Development Environment Setup](#development-environment-setup)
- [Testing the Integration](#testing-the-integration)
- [API Reference](#api-reference)
- [Troubleshooting](#troubleshooting)
- [Additional Documentation](#additional-documentation)

---

## Overview

This feature integrates Evolution API with Chatwoot to provide WhatsApp messaging capabilities for the Brazilian market. Evolution API is a popular, cost-effective WhatsApp Web automation service that allows businesses to receive and send WhatsApp messages through Chatwoot's unified interface.

### Evolution API - Chatwoot BR Fork

This integration uses the **Chatwoot BR fork** of Evolution API (`ghcr.io/chatwoot-br/evolution-api:next`), which includes:

- **Direct Database Integration**: Shares PostgreSQL database with Chatwoot using separate schemas
- **Enhanced Chatwoot Support**: Built-in Chatwoot integration settings and optimizations
- **Brazilian Market Focus**: Specialized features like Brazilian contact merging
- **Production Ready**: Based on Evolution API v2.x with additional stability improvements

**Why a fork?**
- Tighter integration with Chatwoot's database and architecture
- Eliminates need for MongoDB, simplifying deployment
- Chatwoot-specific features and optimizations
- Better support for multi-tenant scenarios

### Key Features

- ✅ **WhatsApp Channel Creation**: Create WhatsApp inboxes via Evolution API
- ✅ **Instance Management**: Automatic Evolution API instance lifecycle management
- ✅ **Advanced Error Handling**: 7 specific error types with user-friendly messages
- ✅ **Message Reception**: Real-time WhatsApp message reception via webhooks
- ✅ **Contact Management**: Brazilian contact merging and management
- ✅ **Automatic Cleanup**: Instance cleanup on inbox deletion
- ✅ **Production-Ready**: Comprehensive testing and timeout configuration

### Business Value

- **Brazilian Market Focus**: Tap into WhatsApp's 99% penetration in Brazil
- **Cost-Effective**: Affordable alternative to official WhatsApp Business API
- **Easy Setup**: Simplified configuration with environment variable support
- **Reliable**: Robust error handling and timeout management

---

## Architecture

### System Components

```
┌─────────────────┐      ┌──────────────────┐      ┌─────────────────┐
│   Vue 3 UI      │─────▶│   Rails API      │─────▶│  Evolution API  │
│  (Frontend)     │      │   (Backend)      │      │  (chatwoot-br)  │
└─────────────────┘      └──────────────────┘      └─────────────────┘
                                  │                         │
                                  ▼                         ▼
                         ┌──────────────────┐      ┌─────────────────┐
                         │   PostgreSQL     │◀─────│   WhatsApp      │
                         │ (Shared Database)│      │   (Messaging)   │
                         └──────────────────┘      └─────────────────┘
                                  ▲
                                  │
                         ┌──────────────────┐
                         │      Redis       │
                         │  (Shared Cache)  │
                         └──────────────────┘
```

### Component Details

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Frontend** | Vue 3 Composition API | Channel creation UI with form validation |
| **Backend API** | Rails 7.1 | REST API endpoints and business logic |
| **Service Layer** | Evolution::ManagerService | Evolution API integration and error handling |
| **Database** | PostgreSQL | Shared database for Chatwoot + Evolution (separate schemas) |
| **Evolution API** | Docker (chatwoot-br fork) | WhatsApp Web automation service |
| **Redis** | Docker container | Shared caching between Chatwoot and Evolution |

### Data Flow

1. **Channel Creation**:
   - User fills form in Vue component → Vuex store action
   - API call to `/api/v1/accounts/{account_id}/channels/evolution`
   - `EvolutionChannelsController` validates and authorizes
   - `Evolution::ManagerService` creates instance via Evolution API
   - Inbox and Channel records saved to PostgreSQL
   - Success response or error returned to frontend

2. **Message Reception** (Future):
   - Customer sends WhatsApp message
   - Evolution API receives via WhatsApp Web
   - Webhook POST to Chatwoot `/webhooks/whatsapp`
   - Message processed and conversation created/updated
   - Real-time notification to agent dashboard via WebSocket

---

## Development Environment Setup

### Prerequisites

- Docker and Docker Compose installed
- Ruby 3.4.4
- Node.js 23.x with pnpm 10.x
- Git

### 1. Clone and Initial Setup

```bash
# Clone the repository (if not already done)
git clone <repository-url>
cd chatwoot

# Install dependencies
bundle install
pnpm install
```

### 2. Environment Configuration

Create or update your `.env` file with Evolution API settings:

```bash
# Evolution API Configuration (Development)
EVOLUTION_API_URL=http://localhost:8080
EVOLUTION_API_KEY=evolution_dev_api_key_change_in_production

# Redis Configuration (required for Evolution API)
REDIS_PASSWORD=your_redis_password_here
```

### 3. Start Services with Docker Compose

```bash
# Start all services including Evolution API
docker compose -f docker-compose.dev.yaml up -d

# Check service health
docker compose -f docker-compose.dev.yaml ps

# View Evolution API logs
docker compose -f docker-compose.dev.yaml logs
```

### 4. Initialize Database

```bash
# Create, migrate, and seed database
make db

# Or run individually
bundle exec rails db:create
bundle exec rails db:migrate
bundle exec rails db:seed
```

### 5. Start Chatwoot Application

```bash
# Start all Chatwoot services (backend, frontend, workers)
pnpm dev

# Or use Overmind
overmind start -f ./Procfile.dev
```

### Service URLs

Once all services are running, access:

| Service | URL | Credentials |
|---------|-----|-------------|
| **Chatwoot** | http://localhost:3000 | Created during seed |
| **Evolution API** | http://localhost:8080 | API Key: `evolution_dev_api_key_change_in_production` |
| **Evolution API Health** | http://localhost:8080/health/liveness | N/A |
| **MailHog** | http://localhost:8025 | N/A |
| **PostgreSQL** | localhost:5432 | user: `postgres`, pass: `P@ssw0rd`, db: `chatwoot_dev` |
| **Redis** | localhost:6379 | pass: from `.env` |

> **Note**: Evolution API uses the same PostgreSQL database as Chatwoot but with a separate `evolution` schema for data isolation.

---

## Testing the Integration

### Automated Testing

#### Backend Tests (RSpec)

```bash
# Run all Evolution API related tests
bundle exec rspec spec/services/evolution/
bundle exec rspec spec/controllers/api/v1/accounts/channels/evolution_channels_controller_spec.rb
bundle exec rspec spec/lib/custom_exceptions/evolution_spec.rb
bundle exec rspec spec/models/inbox_spec.rb

# Run with coverage
COVERAGE=true bundle exec rspec spec/services/evolution/
```

**Test Coverage**:
- ✅ 754 lines: Manager Service tests (all error scenarios)
- ✅ 277 lines: Controller tests (authorization, error handling)
- ✅ 283 lines: Custom exception tests
- ✅ 217 lines: Inbox model tests (Evolution detection, cleanup)

#### Frontend Tests (Vitest)

```bash
# Run Evolution component tests
pnpm test evolutionErrorHandler

# Run with watch mode
pnpm test:watch evolutionErrorHandler

# Run with coverage
pnpm test:coverage
```

**Test Coverage**:
- ✅ 229 lines: Error handler utility tests
- ✅ Component rendering and validation tests
- ✅ Error state and retry logic tests

### Manual Testing

#### 1. Create Evolution API Channel

**Prerequisites**: Evolution API container running on `http://localhost:8080`

1. Login to Chatwoot at `http://localhost:3000`
2. Navigate to **Settings → Inboxes → Add Inbox**
3. Select **WhatsApp** channel
4. Select **Evolution API** integration
5. Fill in the form:
   - **API URL**: `http://localhost:8080` (pre-filled from env)
   - **API Key**: `evolution_dev_api_key_change_in_production` (pre-filled)
   - **Phone Number**: Any valid E.164 format (e.g., `+5511999998888`)
   - **Instance Name**: Auto-generated or custom (e.g., `test_instance_001`)
6. Click **Create WhatsApp Channel**

**Expected Result**:
- ✅ Success message displayed
- ✅ Redirected to agent assignment page
- ✅ New inbox appears in Settings → Inboxes
- ✅ Evolution API instance created (verify via Evolution API manager)

#### 2. Verify Evolution API Instance

Check that the instance was created in Evolution API:

```bash
# Using curl
curl -X GET http://localhost:8080/instance/fetchInstances \
  -H "apikey: evolution_dev_api_key_change_in_production"

# Expected response includes your instance
{
  "instance": {
    "instanceName": "test_instance_001",
    "status": "open",
    "integration": "WHATSAPP-BAILEYS"
  }
}
```

#### 3. Test Error Handling

Test various error scenarios to verify error handling:

**A. Invalid API Key**
```bash
# Temporarily change EVOLUTION_API_KEY in .env to invalid value
# Try creating channel → Should show "Authentication Error (401)"
```

**B. Evolution API Unavailable**
```bash
# Stop Evolution API container
docker compose -f docker-compose.dev.yaml stop evolution-api

# Try creating channel → Should show "Service Unavailable (503)"
# Check retry logic and troubleshooting tips are displayed

# Restart Evolution API
docker compose -f docker-compose.dev.yaml start evolution-api
```

**C. Network Timeout**
```bash
# Use a non-existent API URL in the form
# API URL: http://192.0.2.1:8080 (TEST-NET-1, non-routable)
# Should timeout after 30s → Shows "Network Timeout (504)"
```

**D. Duplicate Instance**
```bash
# Create channel with instance name "test_duplicate"
# Try creating another channel with same instance name
# Should show "Instance Conflict (409)"
```

#### 4. Test Instance Cleanup

Verify automatic cleanup on inbox deletion:

```bash
# 1. Create a test inbox via UI (e.g., instance name "cleanup_test")

# 2. Verify instance exists in Evolution API
curl -X GET http://localhost:8080/instance/fetchInstances \
  -H "apikey: evolution_dev_api_key_change_in_production"

# 3. Delete the inbox in Chatwoot UI (Settings → Inboxes → Delete)

# 4. Check Rails logs for cleanup activity
tail -f log/development.log | grep -i "evolution.*cleanup"

# 5. Verify instance removed from Evolution API
curl -X GET http://localhost:8080/instance/fetchInstances \
  -H "apikey: evolution_dev_api_key_change_in_production"
# Instance should no longer appear in list
```

### End-to-End Testing (E2E)

#### Complete Flow Test

```bash
# 1. Start all services
docker compose -f docker-compose.dev.yaml up -d
pnpm dev

# 2. Create channel via UI
# Follow steps in "Create Evolution API Channel" above

# 3. Verify database records
bundle exec rails console
> inbox = Inbox.last
> inbox.channel_type # => "Channel::Whatsapp"
> inbox.channel.provider # => "evolution_api" (check implementation)
> inbox.channel.provider_config # Should contain Evolution API details

# 4. Verify Evolution API instance
# Use curl command from "Verify Evolution API Instance" above

# 5. Clean up
# Delete inbox via UI
# Verify cleanup via curl command

# 6. Stop services
docker compose -f docker-compose.dev.yaml down
```

---

## API Reference

### REST Endpoints

#### Create Evolution Channel

**Endpoint**: `POST /api/v1/accounts/{account_id}/channels/evolution`

**Headers**:
```
Content-Type: application/json
api_access_token: {your_chatwoot_api_token}
```

**Request Body**:
```json
{
  "api_url": "http://localhost:8080",
  "api_key": "evolution_dev_api_key_change_in_production",
  "phone_number": "+5511999998888",
  "instance_name": "my_instance"
}
```

**Success Response** (200 OK):
```json
{
  "id": 123,
  "name": "WhatsApp (+5511999998888)",
  "channel_type": "Channel::Whatsapp",
  "provider": "evolution_api",
  "phone_number": "+5511999998888",
  "created_at": "2025-09-20T10:30:00Z"
}
```

**Error Responses**:

| Status | Error Type | Description |
|--------|-----------|-------------|
| 400 | Invalid Configuration | Missing required parameters |
| 401 | Authentication Error | Invalid Evolution API key |
| 409 | Instance Conflict | Instance name already exists |
| 422 | Instance Creation Failed | Evolution API validation error |
| 503 | Service Unavailable | Evolution API is down |
| 504 | Network Timeout | Request timeout (30s exceeded) |

### Evolution API Endpoints

Evolution API provides several useful endpoints for testing:

```bash
# Base URL: http://localhost:8080
# Header: apikey: evolution_dev_api_key_change_in_production

# List all instances
GET /instance/fetchInstances

# Get instance details
GET /instance/connectionState/{instance_name}

# Delete instance
DELETE /instance/delete/{instance_name}

# Health check
GET /
```

---

## Troubleshooting

### Common Issues

#### 1. Evolution API Container Won't Start

**Symptoms**: Container exits immediately or shows errors

**Solutions**:
```bash
# Check logs
docker compose -f docker-compose.dev.yaml logs evolution-api

# Common causes:
# - PostgreSQL not ready: Wait for database migrations
docker compose -f docker-compose.dev.yaml logs postgres
docker compose -f docker-compose.dev.yaml restart evolution-api

# - Port 8080 already in use
lsof -i :8080  # Find process using port
kill -9 {PID}  # Kill process

# - Redis connection failed: Check REDIS_PASSWORD in .env
docker compose -f docker-compose.dev.yaml restart redis evolution-api

# - Database connection failed: Verify PostgreSQL is running
docker compose -f docker-compose.dev.yaml ps postgres
# Check Evolution schema exists
docker compose -f docker-compose.dev.yaml exec postgres psql -U postgres -d chatwoot_dev -c "\dn"
```

#### 2. Channel Creation Returns 503 Error

**Symptoms**: "Evolution API service unavailable" error

**Solutions**:
```bash
# 1. Check Evolution API is running
docker compose -f docker-compose.dev.yaml ps evolution-api
# Should show "Up" status with "healthy" state

# 2. Test Evolution API health endpoint
curl -f http://localhost:8080/health/liveness || echo "Evolution API is down"

# 3. Check healthcheck status
docker compose -f docker-compose.dev.yaml ps evolution-api
# Look for "healthy" in STATUS column

# 4. View real-time logs
docker compose -f docker-compose.dev.yaml logs -f evolution-api

# 5. Restart if needed
docker compose -f docker-compose.dev.yaml restart evolution-api
```

#### 3. Authentication Error (401)

**Symptoms**: "Invalid API key" error when creating channel

**Solutions**:
```bash
# 1. Verify API key in .env matches docker-compose.dev.yaml
grep EVOLUTION_API_KEY .env
# Should be: evolution_dev_api_key_change_in_production

# 2. Restart Chatwoot to reload .env
overmind restart

# 3. Test API key with curl
curl -X GET http://localhost:8080/instance/fetchInstances \
  -H "apikey: evolution_dev_api_key_change_in_production"
# Should return JSON, not 401 error
```

#### 4. Network Timeout (504)

**Symptoms**: Request hangs for 30 seconds then fails

**Solutions**:
```bash
# 1. Verify Evolution API URL is accessible
curl -I http://localhost:8080
# Should return HTTP/1.1 200 OK quickly

# 2. Check network connectivity
ping -c 3 localhost

# 3. If using custom URL, verify DNS resolution
nslookup your-evolution-domain.com

# 4. Check firewall rules
# Ensure port 8080 is open

# 5. Review timeout configuration (30s total)
# app/services/evolution/manager_service.rb:
# - open_timeout: 10 (connection timeout)
# - read_timeout: 20 (read timeout)
# - write_timeout: 20 (write timeout)
```

#### 5. Instance Cleanup Doesn't Work

**Symptoms**: Evolution instance remains after deleting Chatwoot inbox

**Solutions**:
```bash
# 1. Check Rails logs for cleanup errors
tail -f log/development.log | grep -i "evolution.*cleanup"

# 2. Verify before_destroy hook in Inbox model
# app/models/inbox.rb should have cleanup_evolution_instance callback

# 3. Manual cleanup if needed
curl -X DELETE http://localhost:8080/instance/delete/{instance_name} \
  -H "apikey: evolution_dev_api_key_change_in_production"

# 4. Check if inbox was soft-deleted vs hard-deleted
bundle exec rails console
> Inbox.with_deleted.find(inbox_id).really_destroy!
```

#### 6. Frontend Tests Failing

**Symptoms**: Vitest tests fail for evolutionErrorHandler

**Solutions**:
```bash
# 1. Clear node modules and reinstall
rm -rf node_modules pnpm-lock.yaml
pnpm install

# 2. Run tests with verbose output
pnpm test evolutionErrorHandler --reporter=verbose

# 3. Check for missing dependencies
pnpm list vitest

# 4. Run single test file
pnpm test app/javascript/dashboard/helper/specs/evolutionErrorHandler.spec.js
```

### Debug Mode

Enable detailed logging for debugging:

```ruby
# In Rails console or add to config/environments/development.rb
Rails.logger.level = :debug

# Check Evolution API response in detail
Evolution::ManagerService.new(account, params).create_instance
```

### Useful Commands

```bash
# View all Docker containers with health status
docker compose -f docker-compose.dev.yaml ps

# View Evolution API environment variables
docker compose -f docker-compose.dev.yaml exec evolution-api env | grep -i evolution

# Check Evolution API health
curl http://localhost:8080/health/liveness
curl http://localhost:8080/health/readiness

# Access PostgreSQL and check Evolution schema
docker compose -f docker-compose.dev.yaml exec postgres psql -U postgres -d chatwoot_dev
\dn                          # List schemas (should include 'evolution')
\dt evolution.*              # List Evolution API tables
SELECT * FROM evolution._prisma_migrations;  # Check migrations

# Check Redis data
docker compose -f docker-compose.dev.yaml exec redis redis-cli -a $REDIS_PASSWORD
> KEYS evolution:*           # List Evolution-prefixed keys
> GET evolution:instances    # View instances cache

# Tail all service logs
docker compose -f docker-compose.dev.yaml logs -f

# Tail specific service logs
docker compose -f docker-compose.dev.yaml logs -f evolution-api
docker compose -f docker-compose.dev.yaml logs -f postgres

# Restart specific service
docker compose -f docker-compose.dev.yaml restart evolution-api

# Clean up everything (WARNING: deletes all data)
docker compose -f docker-compose.dev.yaml down -v
```

---

## Additional Documentation

### Related Files

- **Feature Specification**: [FEAT#001-evolution-api-whatsapp-integration.md](./FEAT%23001-evolution-api-whatsapp-integration.md)
- **Error Handling Guide**: [evolution_api_error_handling.md](./evolution_api_error_handling.md)
- **Docker Compose**: [docker-compose.dev.yaml](../../../docker-compose.dev.yaml)

### Code Locations

**Backend**:
- Service: `app/services/evolution/manager_service.rb`
- Controller: `app/controllers/api/v1/accounts/channels/evolution_channels_controller.rb`
- Model: `app/models/inbox.rb`
- Exceptions: `lib/custom_exceptions/evolution.rb`
- Tests: `spec/services/evolution/`, `spec/controllers/`, `spec/lib/custom_exceptions/`

**Frontend**:
- Component: `app/javascript/dashboard/routes/dashboard/settings/inbox/channels/Evolution.vue`
- Error Handler: `app/javascript/dashboard/helper/evolutionErrorHandler.js`
- Store Actions: `app/javascript/dashboard/store/modules/inboxes/channelActions.js`
- Tests: `app/javascript/dashboard/helper/specs/evolutionErrorHandler.spec.js`
- I18n: `app/javascript/dashboard/i18n/locale/en.json`, `pt_BR.json`

### External Resources

- **Evolution API (Chatwoot BR Fork)**: https://github.com/chatwoot-br/evolution-api
  - Branch: `next`
  - Docker Image: `ghcr.io/chatwoot-br/evolution-api:next`
  - Architecture Guide: [AGENTS.md](https://github.com/chatwoot-br/evolution-api/blob/next/AGENTS.md)
  - Helm Charts: [charts/evolution](https://github.com/chatwoot-br/evolution-api/tree/next/charts/evolution)
- **Evolution API (Upstream)**: https://github.com/EvolutionAPI/evolution-api
- **Evolution API Documentation**: https://doc.evolution-api.com/
- **WhatsApp Business API**: https://developers.facebook.com/docs/whatsapp
- **Chatwoot Documentation**: https://www.chatwoot.com/docs

### Support

For issues or questions:

1. Check this README and related documentation
2. Review error messages and troubleshooting section
3. Check existing tests for examples
4. Review Evolution API logs for detailed error information
5. Open an issue with detailed reproduction steps

---

## Quick Reference

### Environment Variables

```bash
# Required
EVOLUTION_API_URL=http://localhost:8080
EVOLUTION_API_KEY=evolution_dev_api_key_change_in_production
REDIS_PASSWORD=your_redis_password

# Optional (with defaults)
DATABASE_URL=postgresql://postgres:P@ssw0rd@localhost:5432/chatwoot_dev
REDIS_URL=redis://localhost:6379
```

### Docker Compose Commands

```bash
# Start services
docker compose -f docker-compose.dev.yaml up -d

# Stop services
docker compose -f docker-compose.dev.yaml stop

# View logs
docker compose -f docker-compose.dev.yaml logs -f evolution-api

# Restart service
docker compose -f docker-compose.dev.yaml restart evolution-api

# Clean up
docker compose -f docker-compose.dev.yaml down -v
```

### Testing Commands

```bash
# Backend
bundle exec rspec spec/services/evolution/
bundle exec rspec spec/controllers/api/v1/accounts/channels/evolution_channels_controller_spec.rb

# Frontend
pnpm test evolutionErrorHandler
pnpm test:watch

# Full suite
bundle exec rspec
pnpm test
```

---

**Last Updated**: 2025-09-20
**Maintainer**: Chatwoot BR Team
**Status**: ✅ Production-Ready
