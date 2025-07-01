# VegaVision Simple Production Setup

## 🚀 Quick Setup (5 minutes)

### 1. Prepare Your VM
Just make sure you have:
- Docker installed
- GitLab Runner registered with `self-hosted` tag

### 2. Set GitLab Variables
Go to **GitLab Project → Settings → CI/CD → Variables** and add:

| Variable | Value | Example |
|----------|-------|---------|
| `ORG` | Your organization name | `acme` |
| `DATABASE_URL` | Your database connection | `postgresql://user:pass@host:5432/db` |
| `POSTGRES_HOST` | Database host | `db.example.com` |
| `POSTGRES_DATABASE` | Database name | `vegavision_acme` |
| `POSTGRES_USERNAME` | Database user | `acme_user` |
| `POSTGRES_PASSWORD` | Database password | `secret123` |
| `REDIS_PASSWORD` | Redis password | `redis_secret` |
| `SECRET_KEY_BASE` | Rails secret | Generate with `openssl rand -hex 64` |
| `FRONTEND_URL` | Your domain | `https://acme.yourdomain.com` |
| `DOCKER_HUB_USERNAME` | Docker Hub user | `your_username` |
| `DOCKER_HUB_PASSWORD` | Docker Hub password | `your_password` |

### 3. Deploy
1. Push code to `main` branch
2. Go to **CI/CD → Pipelines**
3. Click **Run Pipeline**
4. When build completes, click ▶️ on `deploy_production`

## 🏢 Multiple Organizations

For each organization, create separate GitLab projects or set different `ORG` values:

```bash
# Organization 1
ORG=acme
FRONTEND_URL=https://acme.yourdomain.com

# Organization 2  
ORG=client1
FRONTEND_URL=https://client1.yourdomain.com
```

Each will create:
- Containers: `vv-acme-helpdesk-Rails`, `vv-client1-helpdesk-Rails`
- Directories: `~/vv-acme-helpdesk/`, `~/vv-client1-helpdesk/`
- Volumes: `/vv-volumes/acme-helpdesk/`, `/vv-volumes/client1-helpdesk/`

## 🌐 NPM Integration

All organizations share the `vv-helpdesk` network:

```bash
# Connect NPM to shared network
docker network connect vv-helpdesk your_npm_container

# Proxy settings for each org:
acme.yourdomain.com → vv-acme-helpdesk-Rails:3000
client1.yourdomain.com → vv-client1-helpdesk-Rails:3000
```

## 🎛️ Pipeline Jobs

- **`build_image`**: Builds and pushes Docker image (automatic)
- **`deploy_production`**: Deploys your organization (manual)
- **`health_check`**: Shows container status (manual)
- **`stop_production`**: Stops deployment (manual)

## ⚡ Manual Commands

```bash
# Check specific organization
cd ~/vv-acme-helpdesk
docker-compose ps

# View logs
docker-compose logs -f vv-acme-helpdesk-Rails

# Restart
docker-compose restart

# Update
docker-compose pull && docker-compose up -d
```

## 🔧 Troubleshooting

**Pipeline fails?**
- Check GitLab variables are set
- Verify runner has `self-hosted` tag

**Containers won't start?**
- Check database connection with `DATABASE_URL`
- Verify `REDIS_PASSWORD` is set

**Can't access from NPM?**
- Ensure NPM is connected to `vv-helpdesk` network
- Check container names: `docker ps | grep vv-`

That's it! No scripts to run, no files to download - everything happens in GitLab CI.
