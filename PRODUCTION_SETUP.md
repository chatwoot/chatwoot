# VegaVision Multi-Organization Production Setup Guide

This guide explains how to set up VegaVision for production deployment supporting multiple organizations using GitLab CI/CD with a self-hosted GitLab runner and GitLab Secure Files.

## Architecture Overview

This setup supports deploying multiple VegaVision instances for different organizations on the same VM:

```
GitLab CI/CD Pipeline
     ↓
Self-Hosted GitLab Runner (VM)
     ↓
Multiple Docker Compose Stacks:
├── vv-acme-helpdesk-Rails
├── vv-client1-helpdesk-Rails  
├── vv-client2-helpdesk-Rails
└── Shared NPM Proxy → Internet
```

## Prerequisites

- VM with Docker and GitLab Runner
- GitLab project with appropriate permissions
- Separate `.env` files for each organization

## GitLab Runner Setup

### 1. Run Setup Script
```bash
curl -fsSL https://raw.githubusercontent.com/your-repo/main/scripts/setup-production.sh | bash
```

### 2. Register GitLab Runner
```bash
sudo gitlab-runner register \
  --url "https://your-gitlab-instance.com/" \
  --token "your-registration-token" \
  --executor "docker" \
  --docker-image "docker:24.0.5" \
  --tag-list "self-hosted" \
  --run-untagged="false" \
  --locked="false"
```

## Organization Configuration

### Required GitLab CI/CD Variables

Configure these variables in **Settings → CI/CD → Variables**:

| Variable | Description | Example | Required |
|----------|-------------|---------|----------|
| `ORG` | Organization identifier | `acme`, `client1` | ✅ |
| `SECURE_FILES_TOKEN` | Personal/Project access token | `glpat-xxxxx` | ✅ |
| `DOCKER_HUB_USERNAME` | Docker Hub username | `your-username` | ✅ |
| `DOCKER_HUB_PASSWORD` | Docker Hub password/token | `your-token` | ✅ |
| `FRONTEND_URL` | Organization's domain URL | `https://acme.com` | ✅ |

### Multi-Organization Setup

For each organization, create separate GitLab projects or use environment-specific variables:

```bash
# Organization: ACME
ORG=acme
FRONTEND_URL=https://acme.yourdomain.com

# Organization: Client1  
ORG=client1
FRONTEND_URL=https://client1.yourdomain.com
```

## GitLab Secure Files Configuration

### 1. Upload Organization Environment Files

For each organization, upload a `.env` file to **Settings → CI/CD → Secure Files**:

1. Create organization-specific `.env` files based on `.env.production` template
2. Upload each as `.env` (the pipeline downloads the same filename for all orgs)
3. Use separate GitLab projects or branches for different organizations

### 2. Environment File Template

Each organization's `.env` file should contain:

```bash
# Application Settings
NODE_ENV=production
RAILS_ENV=production
INSTALLATION_ENV=docker
RAILS_SERVE_STATIC_FILES=true

# Organization-specific Database Configuration
DATABASE_URL=postgresql://acme_user:pass@db-acme.com:5432/vegavision_acme
POSTGRES_HOST=db-acme.com
POSTGRES_PORT=5432
POSTGRES_DATABASE=vegavision_acme
POSTGRES_USERNAME=acme_user
POSTGRES_PASSWORD=secure_password

# Redis Configuration (uses internal container)
REDIS_URL=redis://:redis_acme_pass@127.0.0.1:6377/0
REDIS_PASSWORD=redis_acme_pass

# Organization-specific Secrets
SECRET_KEY_BASE=acme-generated-secret-key
FRONTEND_URL=https://acme.yourdomain.com

# Organization-specific Email
MAILER_SENDER_EMAIL=noreply@acme.yourdomain.com
SMTP_DOMAIN=acme.yourdomain.com
# ... other SMTP settings
```

## Deployment Process

### Directory Structure (Per Organization)
```
VM File System:
├── ~/vv-acme-helpdesk/
│   ├── docker-compose.org.yml
│   └── .env
├── ~/vv-client1-helpdesk/
│   ├── docker-compose.org.yml  
│   └── .env
└── /vv-volumes/
    ├── acme-helpdesk/
    │   ├── storage_data/
    │   └── redis_data/
    └── client1-helpdesk/
        ├── storage_data/
        └── redis_data/
```

### Container Naming Convention
```
Organization: acme
├── vv-acme-helpdesk-Rails
├── vv-acme-helpdesk-Sidekiq
└── vv-acme-helpdesk-Redis

Organization: client1  
├── vv-client1-helpdesk-Rails
├── vv-client1-helpdesk-Sidekiq
└── vv-client1-helpdesk-Redis
```

### Network Configuration
All organizations share the `vv-helpdesk` network for NPM integration:
```bash
docker network ls
# NETWORK ID   NAME         DRIVER
# xxx          vv-helpdesk  bridge
```

## NPM (Nginx Proxy Manager) Configuration

### Option 1: NPM Container on Same Host
Connect NPM container to the `vv-helpdesk` network:
```bash
docker network connect vv-helpdesk npm_container_name
```

**NPM Proxy Settings:**
- **Destination Host:** `VV-Helpdesk-Rails`
- **Port:** `3000`
- **Scheme:** `http`

### Option 2: NPM on Different Host
**NPM Proxy Settings:**
- **Destination Host:** `your-app-server-ip`
- **Port:** `3001`
- **Scheme:** `http`

## NPM (Nginx Proxy Manager) Configuration

### Connect NPM to Shared Network
```bash
# Connect NPM container to the shared network
docker network connect vv-helpdesk npm_container_name
```

### Organization-Specific Proxy Settings

Each organization gets its own proxy configuration:

#### Organization: ACME
- **Domain:** `acme.yourdomain.com`
- **Destination Host:** `vv-acme-helpdesk-Rails`  
- **Port:** `3000`
- **Scheme:** `http`

#### Organization: Client1
- **Domain:** `client1.yourdomain.com`
- **Destination Host:** `vv-client1-helpdesk-Rails`
- **Port:** `3000` 
- **Scheme:** `http`

### Alternative: External NPM
If NPM is on a different server:
- **Destination Host:** `your-vm-ip`
- **Port:** `3001` (mapped from container port 3000)

## Manual Operations

### Organization-Specific Commands
```bash
# Check specific organization
cd ~/vv-acme-helpdesk
docker-compose -f docker-compose.org.yml ps

# View logs for specific org
docker-compose -f docker-compose.org.yml logs -f vv-acme-helpdesk-Rails

# Restart specific organization
docker-compose -f docker-compose.org.yml restart

# List all organizations
ls ~/vv-*-helpdesk/
```

### Cross-Organization Management
```bash
# View all VegaVision containers
docker ps | grep "vv-.*-helpdesk"

# Check shared network
docker network inspect vv-helpdesk

# Monitor resource usage across orgs
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
```

### Using GitLab CI Manual Jobs
1. **Set ORG variable** in GitLab CI/CD variables
2. Go to **CI/CD → Pipelines**
3. Use manual jobs:
   - `deploy_production`: Deploy specific organization
   - `health_check`: Check organization health  
   - `rollback_production`: Rollback specific organization

## Troubleshooting

### Organization-Specific Issues
```bash
# Check organization deployment
cd ~/vv-$ORG-helpdesk
docker-compose -f docker-compose.org.yml ps
docker-compose -f docker-compose.org.yml logs --tail=50

# Verify network connectivity between orgs
docker exec vv-acme-helpdesk-Rails ping vv-client1-helpdesk-Rails
```

### Volume and Permission Issues
```bash
# Check organization volumes
ls -la /vv-volumes/
du -sh /vv-volumes/*

# Fix permissions if needed
sudo chown -R gitlab-runner:gitlab-runner /vv-volumes/
```

### Pipeline Debugging
```bash
# Check if correct .env was downloaded
cat ~/vv-$ORG-helpdesk/.env | grep FRONTEND_URL

# Verify container naming
docker ps --format "table {{.Names}}\t{{.Status}}" | grep vv-$ORG
```

## Security Notes

1. **Organization Isolation**: Each org has separate volumes and containers
2. **Shared Network**: All orgs share `vv-helpdesk` network (secure for NPM integration)
3. **Environment Separation**: Each org has separate `.env` files in Secure Files
4. **Access Control**: Use GitLab's environment-specific protection rules
5. **Resource Monitoring**: Monitor per-organization resource usage

## Best Practices

### Organization Management
1. **Naming Convention**: Always use lowercase, no special characters in ORG
2. **Database Separation**: Each org should have separate databases
3. **Resource Limits**: Consider Docker resource constraints per organization
4. **Monitoring**: Set up organization-specific monitoring and alerting

### GitLab Project Structure
- **Option 1**: Separate GitLab projects per organization
- **Option 2**: Single project with environment-based deployments
- **Option 3**: Branches per organization with environment-specific variables

### Scaling Considerations
- **Vertical Scaling**: Increase VM resources as organizations grow
- **Horizontal Scaling**: Deploy additional VMs with load balancing
- **Resource Monitoring**: Monitor CPU, memory, and disk usage per organization

## Manual Operations

### Direct Docker Commands
```bash
# Navigate to application directory
cd ~/vegavision

# Check container status
docker-compose -f docker-compose.prod.yml ps

# View logs
docker-compose -f docker-compose.prod.yml logs -f VV-Helpdesk-Rails
docker-compose -f docker-compose.prod.yml logs -f VV-Helpdesk-Sidekiq

# Restart services
docker-compose -f docker-compose.prod.yml restart

# Pull and update
docker-compose -f docker-compose.prod.yml pull
docker-compose -f docker-compose.prod.yml up -d
```

### Using GitLab CI Manual Jobs
1. Go to GitLab project → CI/CD → Pipelines
2. Click on latest pipeline
3. Use manual jobs:
   - Click ▶️ on `deploy_production` to deploy
   - Click ▶️ on `health_check` to check status
   - Click ▶️ on `rollback_production` if needed

## Troubleshooting

### Check Pipeline Logs
```bash
# If .env download fails, check:
# 1. SECURE_FILES_TOKEN is set with correct permissions
# 2. .env file is uploaded to Secure Files
# 3. Token has read_api scope
```

### Check Application Status
```bash
cd ~/vegavision
docker-compose -f docker-compose.prod.yml ps
docker-compose -f docker-compose.prod.yml logs --tail=50
```

### Check Network Connectivity
```bash
# List networks
docker network ls

# Check if containers are on vv-helpdesk network
docker network inspect vv-helpdesk

# Test internal connectivity
docker exec VV-Helpdesk-Rails ping VV-Helpdesk-Redis
```

### Volume Permissions
```bash
# Ensure volume directories exist and have correct permissions
sudo mkdir -p /vv-volumes/storage_data /vv-volumes/redis_data
sudo chown -R $USER:$USER /vv-volumes
```

## Security Notes

1. **Secure Files**: Environment variables are stored securely in GitLab
2. **Runner Security**: Self-hosted runner only has local access
3. **Token Permissions**: Use minimal scope tokens (`read_api` only)
4. **Regular Updates**: Keep Docker images and runner updated
5. **Access Control**: Limit who can trigger manual deployments

## CI/CD Pipeline Variables Reference

| Variable | Purpose | Example |
|----------|---------|---------|
| `SECURE_FILES_TOKEN` | Download .env from Secure Files | `glpat-xxxxxxxxxxxx` |
| `DOCKER_HUB_USERNAME` | Push images to Docker Hub | `your-username` |
| `DOCKER_HUB_PASSWORD` | Docker Hub authentication | `your-token` |
| `FRONTEND_URL` | Environment URL for GitLab | `https://yourdomain.com` |

## Updating the Application

1. **Push code changes** to `main`/`master` branch
2. **Pipeline runs automatically** (build + test stages)
3. **Manual deployment** via GitLab UI or API
4. **Monitor logs** through GitLab or directly on server
5. **Rollback if needed** using rollback job
