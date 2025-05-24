# Chatwoot Deployment Guide

A step-by-step guide to deploy [Chatwoot](https://github.com/chatwoot/chatwoot) using Docker for development and production environments.

## Prerequisites

### System Requirements
- **OS:** macOS/Linux
- **Mac chip Architachture:** ARM

### Software Requirements
- Docker Desktop(for Mac user only)
- Docker Compose
- Git
- Terminal 
- Code Editor (VS Code recommended)

### Verify Installations
```bash
docker --version          # Docker 20.10.10+
docker compose version    # Docker Compose v2.14.1+
git --version             # Git 2.30+
```

---

## Installation

### 1. Clone Repository
```bash
git clone https://github.com/chatwoot/chatwoot.git
cd chatwoot
```

### 2. Configure Environment
```bash
# Create environment files
cp .env.example .env
cp docker-compose.production.yaml docker-compose.yaml
```

---

## Configuration

### `.env` File Essentials
```env
FRONTEND_URL=http://localhost:3000
SECRET_KEY_BASE=$(openssl rand -hex 32 | tr -d '\n' | cut -c1-63 )
ENABLE_ACCOUNT_SIGNUP=true #set it to true if you want to sign up new user account 

# POSTGRES_DATABASE
POSTGRES_HOST=postgres
POSTGRES_USERNAME=postgres
POSTGRES_PASSWORD=123456

# Redis
#for the URL: redis://:password@host:port/db_number
REDIS_URL=redis://:password@redis:6379
REDIS_PASSWORD=set your own password here

```


### `docker-compose.yaml` File Essentials
```env
services:
  base: &base
    image: chatwoot/chatwoot:latest
    env_file: .env.example ## change this to .env or .env.example whatever you want to use
    volumes:
      - storage_data:/app/storage

  rails:
    platform: linux/amd64 ## for the mac os user

  postgres:
    image: pgvector/pgvector:pg15
    restart: always
    ports:
      - '127.0.0.1:5432:5432'
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      - POSTGRES_DB=chatwoot
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD= ??? # use your own password here
    platform: linux/amd64   

  redis:
    image: redis:alpine
    restart: always
    command: ["sh", "-c", "redis-server --requirepass YOUR_PASSWORD"]
    env_file: .env.example
    volumes:
      - redis_data:/data
    ports:
      - '127.0.0.1:6379:6379'
    platform: linux/amd64 

```

---

## Running the Application

### 1. Start Containers
```bash
docker compose up -d
```

### 2. Database Setup
```bash
docker compose run --rm rails bundle exec rails db:chatwoot_prepare
```

### 3. Verify Services
```bash
docker compose ps
```

Expected output:
```
NAME                COMMAND                  SERVICE             STATUS              PORTS
chatwoot-postgres-1 "docker-entrypoint.s…"   postgres            running             
chatwoot-redis-1    "docker-entrypoint.s…"   redis               running             
chatwoot-rails-1    "docker/entrypoints/…"   rails               running             0.0.0.0:3000->3000/tcp
```
OR

```bash
curl -I http://localhost:3000/api
```

Expected output:
```
HTTP/1.1 200 OK
X-Frame-Options: SAMEORIGIN
X-XSS-Protection: 0
X-Content-Type-Options: nosniff
X-Download-Options: noopen
X-Permitted-Cross-Domain-Policies: none
Referrer-Policy: strict-origin-when-cross-origin
Content-Type: application/json; charset=utf-8
Vary: Accept
ETag: W/"f78b731a773e74a35e18b2022d685885"
Cache-Control: max-age=0, private, must-revalidate
X-Request-Id: fc5b6a9a-d66d-4234-a992-2c3549d5c4eb
X-Runtime: 0.016162
Content-Length: 0
```
---

## Testing Functionality

### Web Frontend Interface
- Open [http://localhost:3000](http://localhost:3000)
- Login with admin credentials or sign up new user account
- Verify dashboard loads

![Screenshot 2025-05-23 at 6 09 43 PM](https://github.com/user-attachments/assets/817eccab-382f-43a9-8ecf-a0d6e6cbd6b2)

---

## Troubleshooting

### Common Issues

#### 1. Port Conflicts
```bash
sudo lsof -i :3000   # Check Rails port
sudo lsof -i :5432   # Check PostgreSQL port
sudo lsof -i :6379   # Check Redis port
```

#### 2. Database Connection Issues
```bash
docker compose logs postgres
docker compose exec postgres psql -U postgres -d chatwoot_production
```

#### 3. Redis Timeouts
```bash
docker compose exec redis redis-cli -a $REDIS_PASSWORD PING
```

#### 4. Docker Daemon Not Running
```bash
# macOS
open -a Docker

# Linux
systemctl status docker
```

---

## Production Considerations

### Monitoring
- Add healthchecks to `docker-compose.yaml`
- Set up Prometheus/Grafana

### Updates
```bash
docker compose pull
docker compose up -d
docker compose run --rm rails bundle exec rails db:chatwoot_prepare
```

---

For more details, refer to the [Chatwoot Documentation](https://www.chatwoot.com/docs) or the [Support Forum](https://www.chatwoot.com/community).

_This README provides a complete workflow for setup the enviornment. Please adjust any values to suit your environment._

## Security

Looking to report a vulnerability? Please refer our [SECURITY.md](./SECURITY.md) file.

## Community

If you need help or just want to hang out, come, say hi on our [Discord](https://discord.gg/cJXdrwS) server.

## Contributors

Thanks goes to all these [wonderful people](https://www.chatwoot.com/docs/contributors):

<a href="https://github.com/chatwoot/chatwoot/graphs/contributors"><img src="https://opencollective.com/chatwoot/contributors.svg?width=890&button=false" /></a>


*Chatwoot* &copy; 2017-2025, Chatwoot Inc - Released under the MIT License.
