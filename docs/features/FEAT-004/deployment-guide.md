# Deployment and Usage Guide

This guide covers everything you need to deploy and use the WhatsApp Web API Multidevice application.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation Methods](#installation-methods)
- [Initial Setup](#initial-setup)
- [Configuration](#configuration)
- [Running the Application](#running-the-application)
- [Deployment Scenarios](#deployment-scenarios)
- [Production Considerations](#production-considerations)
- [Common Use Cases](#common-use-cases)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### Required

- **Operating System**: Linux, macOS, or Windows
- **Architecture**: AMD64 or ARM64
- **WhatsApp Account**: Active WhatsApp account with phone

### Optional

- **FFmpeg**: Required for media compression (video/image processing)
- **Docker**: For containerized deployment
- **PostgreSQL**: For production database (SQLite is default)
- **Reverse Proxy**: For HTTPS and production deployment (nginx, Caddy, Traefik)

### Installing FFmpeg

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install ffmpeg
```

**macOS:**
```bash
brew install ffmpeg
```

**Windows:**
Download from [ffmpeg.org](https://ffmpeg.org/download.html) and add to PATH

## Installation Methods

### Method 1: Pre-built Binary (Recommended)

Download the latest release for your platform:

```bash
# Linux AMD64
wget https://github.com/chatwoot-br/go-whatsapp-web-multidevice/releases/latest/download/whatsapp-linux-amd64

# Linux ARM64
wget https://github.com/chatwoot-br/go-whatsapp-web-multidevice/releases/latest/download/whatsapp-linux-arm64

# macOS AMD64
wget https://github.com/chatwoot-br/go-whatsapp-web-multidevice/releases/latest/download/whatsapp-darwin-amd64

# macOS ARM64 (Apple Silicon)
wget https://github.com/chatwoot-br/go-whatsapp-web-multidevice/releases/latest/download/whatsapp-darwin-arm64

# Make executable
chmod +x whatsapp-*
```

### Method 2: Docker

**GitHub Container Registry:**
```bash
docker pull ghcr.io/chatwoot-br/go-whatsapp-web-multidevice:latest
```

### Method 3: Docker Compose

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  whatsapp:
    image: ghcr.io/chatwoot-br/go-whatsapp-web-multidevice:latest
    container_name: whatsapp-api
    ports:
      - "3000:3000"
    volumes:
      - ./storages:/app/storages
      - ./logs:/app/logs
    environment:
      - APP_PORT=3000
      - APP_DEBUG=false
      - APP_BASIC_AUTH=admin:secret123
      - WHATSAPP_WEBHOOK=https://your-webhook.com/handler
      - WHATSAPP_WEBHOOK_SECRET=your-secret-key
    restart: unless-stopped
```

Run:
```bash
docker-compose up -d
```

### Method 4: Build from Source

```bash
# Clone repository
git clone https://github.com/chatwoot-br/go-whatsapp-web-multidevice.git
cd go-whatsapp-web-multidevice

# Build binary
cd src
go build -o whatsapp

# Run
./whatsapp rest
```

## Initial Setup

### 1. Create Configuration File

Create `src/.env` file (optional, can use CLI flags instead):

```bash
# Application Settings
APP_PORT=3000
APP_DEBUG=false
APP_OS=MyAppName
APP_BASIC_AUTH=user1:pass1,user2:pass2
APP_BASE_PATH=

# Database Settings
DB_URI="file:storages/whatsapp.db?_foreign_keys=on"
DB_KEYS_URI="file::memory:?cache=shared&_foreign_keys=on"

# WhatsApp Settings
WHATSAPP_AUTO_REPLY="Thanks for your message!"
WHATSAPP_AUTO_MARK_READ=false
WHATSAPP_WEBHOOK=https://your-webhook.com/handler
WHATSAPP_WEBHOOK_SECRET=super-secret-key
WHATSAPP_ACCOUNT_VALIDATION=true
WHATSAPP_CHAT_STORAGE=true
```

### 2. Create Required Directories

```bash
mkdir -p storages statics/media statics/qrcode
```

### 3. Set Permissions (Linux/macOS)

```bash
chmod +x whatsapp
chmod 755 storages statics
```

## Configuration

### Configuration Priority

1. **Command-line flags** (highest priority)
2. **Environment variables**
3. **`.env` file** (lowest priority)

### Key Configuration Options

| Flag | Environment Variable | Default | Description |
|------|---------------------|---------|-------------|
| `--port` | `APP_PORT` | 3000 | HTTP server port |
| `--debug` | `APP_DEBUG` | false | Enable debug logging |
| `--os` | `APP_OS` | Chrome | Device name in WhatsApp |
| `-b, --basic-auth` | `APP_BASIC_AUTH` | - | Basic auth (user:pass,user2:pass2) |
| `--base-path` | `APP_BASE_PATH` | - | Base path for subpath deployment |
| `--autoreply` | `WHATSAPP_AUTO_REPLY` | - | Auto-reply message |
| `--auto-mark-read` | `WHATSAPP_AUTO_MARK_READ` | false | Auto-mark messages as read |
| `-w, --webhook` | `WHATSAPP_WEBHOOK` | - | Webhook URLs (comma-separated) |
| `--webhook-secret` | `WHATSAPP_WEBHOOK_SECRET` | secret | HMAC secret for webhooks |

## Running the Application

### REST API Mode

**Using Binary:**
```bash
# Basic
./whatsapp rest

# With configuration
./whatsapp rest --port 8080 --debug true

# With basic auth
./whatsapp rest -b admin:secret123

# With webhook
./whatsapp rest -w https://webhook.site/your-id --webhook-secret mysecret

# All options
./whatsapp rest \
  --port 3000 \
  --debug false \
  --os "MyApp" \
  -b "admin:secret123" \
  --autoreply "Thanks for your message!" \
  -w "https://webhook.site/your-id" \
  --webhook-secret "super-secret"
```

**Using Docker:**
```bash
docker run -d \
  --name whatsapp-api \
  -p 3000:3000 \
  -v $(pwd)/storages:/app/storages \
  -e APP_PORT=3000 \
  -e APP_BASIC_AUTH=admin:secret123 \
  -e WHATSAPP_WEBHOOK=https://webhook.site/your-id \
  ghcr.io/chatwoot-br/go-whatsapp-web-multidevice:latest
```

**Access the application:**
- Web UI: `http://localhost:3000`
- API Docs: See `docs/openapi.yaml` or `docs/openapi.md`

### MCP Mode (Model Context Protocol)

**Using Binary:**
```bash
# Basic
./whatsapp mcp

# With custom port
./whatsapp mcp --port 8080 --host 0.0.0.0
```

**MCP Endpoints:**
- SSE: `http://localhost:8080/sse`
- Message: `http://localhost:8080/message`

### Login to WhatsApp

#### Option 1: QR Code (Web UI)

1. Open browser: `http://localhost:3000`
2. Navigate to Login page
3. Scan QR code with WhatsApp mobile app
4. Wait for connection confirmation

#### Option 2: QR Code (API)

```bash
# Get QR code
curl -X GET http://localhost:3000/app/login \
  -u admin:secret123

# Response includes QR image URL
{
  "code": "SUCCESS",
  "message": "Success",
  "results": {
    "qr_link": "http://localhost:3000/statics/images/qrcode/scan-qr-xxx.png",
    "qr_duration": 30
  }
}
```

#### Option 3: Pairing Code (API)

```bash
# Get pairing code
curl -X GET "http://localhost:3000/app/login-with-code?phone=628912344551" \
  -u admin:secret123

# Response
{
  "code": "SUCCESS",
  "message": "Success",
  "results": {
    "pair_code": "ABCD-1234"
  }
}

# Enter this code in WhatsApp mobile app:
# Settings > Linked Devices > Link a Device > Link with phone number instead
```

## Deployment Scenarios

### Scenario 1: Local Development

```bash
# Quick start with default settings
./whatsapp rest --debug true

# Access at http://localhost:3000
```

### Scenario 2: Server Deployment (Systemd)

Create `/etc/systemd/system/whatsapp.service`:

```ini
[Unit]
Description=WhatsApp Web API
After=network.target

[Service]
Type=simple
User=whatsapp
WorkingDirectory=/opt/whatsapp
ExecStart=/opt/whatsapp/whatsapp rest --port 3000
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=whatsapp

[Install]
WantedBy=multi-user.target
```

Setup and run:
```bash
# Create user and directories
sudo useradd -r -s /bin/false whatsapp
sudo mkdir -p /opt/whatsapp
sudo cp whatsapp /opt/whatsapp/
sudo chown -R whatsapp:whatsapp /opt/whatsapp

# Start service
sudo systemctl daemon-reload
sudo systemctl enable whatsapp
sudo systemctl start whatsapp

# Check status
sudo systemctl status whatsapp
sudo journalctl -u whatsapp -f
```

### Scenario 3: Docker with Nginx Reverse Proxy

**docker-compose.yml:**
```yaml
version: '3.8'

services:
  whatsapp:
    image: ghcr.io/chatwoot-br/go-whatsapp-web-multidevice:latest
    container_name: whatsapp-api
    volumes:
      - ./storages:/app/storages
    environment:
      - APP_PORT=3000
      - APP_BASIC_AUTH=admin:${WHATSAPP_PASSWORD}
      - WHATSAPP_WEBHOOK=${WEBHOOK_URL}
      - WHATSAPP_WEBHOOK_SECRET=${WEBHOOK_SECRET}
    restart: unless-stopped
    networks:
      - whatsapp-net

  nginx:
    image: nginx:alpine
    container_name: whatsapp-nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
    depends_on:
      - whatsapp
    restart: unless-stopped
    networks:
      - whatsapp-net

networks:
  whatsapp-net:
    driver: bridge
```

**nginx.conf:**
```nginx
events {
    worker_connections 1024;
}

http {
    upstream whatsapp {
        server whatsapp:3000;
    }

    server {
        listen 80;
        server_name whatsapp.yourdomain.com;
        return 301 https://$server_name$request_uri;
    }

    server {
        listen 443 ssl http2;
        server_name whatsapp.yourdomain.com;

        ssl_certificate /etc/nginx/ssl/cert.pem;
        ssl_certificate_key /etc/nginx/ssl/key.pem;

        location / {
            proxy_pass http://whatsapp;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # WebSocket support
        location /ws {
            proxy_pass http://whatsapp;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
        }
    }
}
```

### Scenario 4: Kubernetes Deployment

**deployment.yaml:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: whatsapp-api
  labels:
    app: whatsapp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: whatsapp
  template:
    metadata:
      labels:
        app: whatsapp
    spec:
      containers:
      - name: whatsapp
        image: ghcr.io/chatwoot-br/go-whatsapp-web-multidevice:latest
        ports:
        - containerPort: 3000
        env:
        - name: APP_PORT
          value: "3000"
        - name: APP_BASIC_AUTH
          valueFrom:
            secretKeyRef:
              name: whatsapp-secret
              key: basic-auth
        - name: WHATSAPP_WEBHOOK
          valueFrom:
            configMapKeyRef:
              name: whatsapp-config
              key: webhook-url
        volumeMounts:
        - name: storage
          mountPath: /app/storages
      volumes:
      - name: storage
        persistentVolumeClaim:
          claimName: whatsapp-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: whatsapp-service
spec:
  selector:
    app: whatsapp
  ports:
  - port: 80
    targetPort: 3000
  type: LoadBalancer
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: whatsapp-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
```

### Scenario 5: Subpath Deployment

Deploy under a specific path (e.g., `/whatsapp-api`):

```bash
./whatsapp rest --base-path="/whatsapp-api" --port 3000

# API accessible at: http://localhost:3000/whatsapp-api/
# Endpoints: http://localhost:3000/whatsapp-api/send/message
```

## Production Considerations

### Security

1. **Always use HTTPS in production**
   - Use reverse proxy (nginx, Caddy, Traefik)
   - Obtain SSL certificate (Let's Encrypt)

2. **Enable Basic Authentication**
   ```bash
   ./whatsapp rest -b "admin:strong-password-here"
   ```

3. **Secure Webhook Secret**
   - Use strong, random secret: `openssl rand -hex 32`
   - Verify HMAC signatures in webhook handler

4. **Environment Variables for Secrets**
   ```bash
   export APP_BASIC_AUTH="admin:${STRONG_PASSWORD}"
   export WHATSAPP_WEBHOOK_SECRET="${WEBHOOK_SECRET}"
   ./whatsapp rest
   ```

### Database

**SQLite (Default):**
- Good for single instance
- No additional setup required
- Files stored in `storages/`

**PostgreSQL (Recommended for Production):**
```bash
# Setup PostgreSQL
DB_URI="postgresql://user:password@localhost:5432/whatsapp?sslmode=disable"

# Run with PostgreSQL
./whatsapp rest
```

### Monitoring

1. **Health Check Endpoint**
   ```bash
   curl http://localhost:3000/app/devices
   ```

2. **Logs**
   - Enable debug mode: `--debug true`
   - Use systemd journal: `journalctl -u whatsapp -f`
   - Docker logs: `docker logs -f whatsapp-api`

3. **Webhook Monitoring**
   - Track webhook delivery failures
   - Monitor retry attempts
   - Check signature verification errors

### Scaling Considerations

⚠️ **Important**: The application cannot run multiple instances with the same WhatsApp account due to WhatsApp's protocol limitations.

**For multiple accounts:**
- Run separate instances per WhatsApp account
- Use different ports for each instance
- Maintain separate databases for each instance

```bash
# Account 1
./whatsapp rest --port 3001 --db-uri "file:storages/account1.db"

# Account 2
./whatsapp rest --port 3002 --db-uri "file:storages/account2.db"
```

### Backup

**Database Backup:**
```bash
# SQLite backup
cp storages/whatsapp.db storages/whatsapp.db.backup
cp storages/chatstorage.db storages/chatstorage.db.backup

# Automated backup script
#!/bin/bash
BACKUP_DIR="/backup/whatsapp/$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"
cp -r storages/* "$BACKUP_DIR/"
```

**Docker Volume Backup:**
```bash
# Create backup
docker run --rm \
  -v whatsapp_storage:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/whatsapp-backup.tar.gz -C /data .

# Restore backup
docker run --rm \
  -v whatsapp_storage:/data \
  -v $(pwd):/backup \
  alpine tar xzf /backup/whatsapp-backup.tar.gz -C /data
```

## Common Use Cases

### Use Case 1: Send Messages via API

```bash
# Send text message
curl -X POST http://localhost:3000/send/message \
  -u admin:secret123 \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "6289685028129@s.whatsapp.net",
    "message": "Hello from WhatsApp API!"
  }'

# Send image
curl -X POST http://localhost:3000/send/image \
  -u admin:secret123 \
  -F "phone=6289685028129@s.whatsapp.net" \
  -F "caption=Check this out!" \
  -F "image=@/path/to/image.jpg"
```

### Use Case 2: Receive Messages via Webhook

**Setup webhook:**
```bash
./whatsapp rest \
  -w "https://your-server.com/webhook" \
  --webhook-secret "your-secret-key"
```

**Webhook handler (Node.js):**
```javascript
const express = require('express');
const crypto = require('crypto');

const app = express();
app.use(express.raw({type: 'application/json'}));

app.post('/webhook', (req, res) => {
  // Verify signature
  const signature = req.headers['x-hub-signature-256'];
  const expectedSig = crypto
    .createHmac('sha256', 'your-secret-key')
    .update(req.body)
    .digest('hex');

  if (`sha256=${expectedSig}` !== signature) {
    return res.status(401).send('Invalid signature');
  }

  // Process webhook
  const data = JSON.parse(req.body);
  console.log('Received:', data);

  res.status(200).send('OK');
});

app.listen(3001);
```

### Use Case 3: Auto-Reply Bot

```bash
./whatsapp rest \
  --autoreply "Thank you for your message! We'll respond shortly." \
  --auto-mark-read true
```

### Use Case 4: Group Management

```bash
# Create group
curl -X POST http://localhost:3000/group \
  -u admin:secret123 \
  -H "Content-Type: application/json" \
  -d '{
    "title": "My Group",
    "participants": ["6281234567890", "6289876543210"]
  }'

# Get group info
curl -X GET "http://localhost:3000/group/info?group_id=120363025982934543@g.us" \
  -u admin:secret123
```

### Use Case 5: MCP Integration with AI

```bash
# Start MCP server
./whatsapp mcp --port 8080

# Connect your AI agent to:
# - SSE: http://localhost:8080/sse
# - Message: http://localhost:8080/message
```

## Troubleshooting

### Connection Issues

**Problem**: Cannot connect to WhatsApp

**Solution**:
```bash
# 1. Check device status
curl http://localhost:3000/app/devices -u admin:secret123

# 2. Try reconnect
curl http://localhost:3000/app/reconnect -u admin:secret123

# 3. Logout and re-login
curl http://localhost:3000/app/logout -u admin:secret123
# Then login again via QR or pairing code
```

### Database Issues

**Problem**: Database locked or corrupted

**Solution**:
```bash
# Stop application
# Backup database
cp storages/whatsapp.db storages/whatsapp.db.backup

# Check database
sqlite3 storages/whatsapp.db "PRAGMA integrity_check;"

# If corrupted, restore from backup or start fresh
rm storages/whatsapp.db
# Login again
```

### Media Issues

**Problem**: Cannot send/receive media

**Solution**:
1. Install FFmpeg: `sudo apt install ffmpeg`
2. Check media size limits (see Configuration)
3. Verify storage permissions:
   ```bash
   chmod 755 statics/media
   ls -la statics/media
   ```

### Webhook Issues

**Problem**: Webhook not receiving events

**Solution**:
1. Verify webhook URL is accessible
2. Check firewall/network settings
3. Test webhook manually:
   ```bash
   curl -X POST https://your-webhook.com/handler \
     -H "Content-Type: application/json" \
     -d '{"test": "message"}'
   ```
4. Enable debug logging:
   ```bash
   ./whatsapp rest --debug true -w "https://your-webhook.com"
   ```

### Docker Issues

**Problem**: Container exits immediately

**Solution**:
```bash
# Check logs
docker logs whatsapp-api

# Run with debug
docker run -it --rm \
  -e APP_DEBUG=true \
  ghcr.io/chatwoot-br/go-whatsapp-web-multidevice:latest rest

# Check volume permissions
docker run -it --rm -v $(pwd)/storages:/app/storages alpine ls -la /app/storages
```

### Performance Issues

**Problem**: High memory/CPU usage

**Solution**:
1. Disable chat storage if not needed:
   ```bash
   WHATSAPP_CHAT_STORAGE=false ./whatsapp rest
   ```
2. Increase media size limits conservatively
3. Monitor with tools:
   ```bash
   # CPU/Memory
   top -p $(pgrep whatsapp)

   # Database size
   du -sh storages/
   ```

## Getting Help

- **Documentation**: See `docs/` folder
  - `openapi.yaml` - Full API reference
  - `openapi.md` - AI Agent guide
  - `webhook-payload.md` - Webhook documentation
- **Issues**: [GitHub Issues](https://github.com/chatwoot-br/go-whatsapp-web-multidevice/issues)
- **Discussions**: [GitHub Discussions](https://github.com/chatwoot-br/go-whatsapp-web-multidevice/discussions)

## Next Steps

1. ✅ Deploy the application using your preferred method
2. ✅ Login to WhatsApp via QR or pairing code
3. ✅ Configure webhooks if needed
4. ✅ Test sending messages via API
5. ✅ Set up monitoring and backups
6. ✅ Review security settings for production

---

**Version**: Compatible with v7.7.0+
**Last Updated**: 2025-10-05
