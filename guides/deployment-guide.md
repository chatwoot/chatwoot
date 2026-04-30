# djc-chat — DigitalOcean Deployment Guide

Fresh install on a new (or wiped) DigitalOcean droplet, using the `daveckw/djc-chat` Docker image and Caddy for auto-TLS.

---

## 0. Prerequisites — info you need ready

- [ ] **Domain** pointed at the droplet's public IP (A record, e.g. `chat.example.com`)
- [ ] **Docker image published** — `daveckw/djc-chat:1` exists on Docker Hub
- [ ] **SMTP provider** account (SendGrid, Mailgun, Postmark, SES…)
- [ ] **Sender email** address you'll send from

---

## 1. Decommission the old droplet (DESTRUCTIVE — fresh start)

> Skip this section if creating a brand-new droplet. Only run if reusing the same droplet.

SSH into the old droplet and run:

```bash
# Stop and remove all containers + volumes (data is irreversibly destroyed)
cd /path/to/old/chatwoot
docker compose down -v
docker system prune -af --volumes
rm -rf /path/to/old/chatwoot
```

**Recommended instead:** spin up a **new droplet** and delete the old one from the DO console once the new install is verified. Zero downtime, free rollback.

---

## 2. Provision the new droplet

DigitalOcean console → Create Droplet:

- **Image:** Ubuntu 24.04 LTS x64
- **Plan:** Basic → Regular SSD → **4 GB RAM / 2 vCPU / 80 GB** (~$24/mo). Bump to 8 GB if 10+ agents.
- **Region:** closest to your users
- **Authentication:** SSH key (paste your public key)
- **Hostname:** `djc-chat-prod`

Once created, copy the public IPv4 and:

1. **Point your domain** at it: A record `chat.yourdomain.com → <droplet IP>`
2. Wait for DNS to propagate (`dig chat.yourdomain.com` should return the IP)

---

## 3. Initial droplet setup

SSH in as root:

```bash
ssh root@<droplet-ip>
```

### 3.1 Create a non-root user

```bash
adduser deploy
usermod -aG sudo deploy
rsync --archive --chown=deploy:deploy ~/.ssh /home/deploy
```

### 3.2 Firewall

```bash
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable
```

### 3.3 Install Docker

```bash
apt update && apt upgrade -y
curl -fsSL https://get.docker.com | sh
usermod -aG docker deploy
```

Log out and SSH back in as `deploy`:

```bash
exit
ssh deploy@<droplet-ip>
docker --version
```

---

## 4. Drop in the deploy files

On your local machine:

```bash
scp -r deploy/ deploy@<droplet-ip>:/home/deploy/djc-chat
```

Then on the droplet:

```bash
sudo mv /home/deploy/djc-chat /opt/djc-chat
sudo chown -R deploy:deploy /opt/djc-chat
cd /opt/djc-chat
cp .env.example .env
```

### 4.1 Generate secrets

```bash
openssl rand -hex 64       # SECRET_KEY_BASE
openssl rand -hex 16       # ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY
openssl rand -hex 16       # ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY
openssl rand -hex 16       # ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT
openssl rand -base64 32    # POSTGRES_PASSWORD
openssl rand -base64 32    # REDIS_PASSWORD (also embed in REDIS_URL)
```

### 4.2 Edit `.env`

```bash
nano /opt/djc-chat/.env
```

Fill in every `REPLACE_ME`, plus:
- `FRONTEND_URL=https://chat.yourdomain.com`
- `MAILER_SENDER_EMAIL`, all `SMTP_*`, `SMTP_DOMAIN`

### 4.3 Edit `Caddyfile`

```bash
nano /opt/djc-chat/Caddyfile
```

Replace `REPLACE_DOMAIN` with `chat.yourdomain.com`.

---

## 5. First boot — initialize database

```bash
cd /opt/djc-chat
docker compose pull
docker compose up -d postgres redis
sleep 10
docker compose run --rm rails bundle exec rails db:chatwoot_prepare
docker compose up -d
```

Verify:

```bash
docker compose ps
docker compose logs -f rails    # wait for "Listening on tcp://0.0.0.0:3000"
```

Caddy obtains a Let's Encrypt cert on first request.

---

## 6. Smoke test

Open `https://chat.yourdomain.com`:

- [ ] TLS green padlock
- [ ] Signup screen loads
- [ ] Create the first super admin (the owner)
- [ ] Send yourself a password reset (verifies SMTP)
- [ ] Settings → Inboxes → create a test inbox

---

## 7. Day-2 operations

### Update image

```bash
cd /opt/djc-chat
# bump tag in docker-compose.yaml (e.g. :1 -> :2)
docker compose pull
docker compose run --rm rails bundle exec rails db:migrate
docker compose up -d
```

### Backup

```bash
mkdir -p /opt/djc-chat/backups
docker compose exec -T postgres pg_dump -U postgres chatwoot_production \
  | gzip > /opt/djc-chat/backups/db-$(date +%F).sql.gz
```

Cron (as `deploy`, `crontab -e`):

```
0 3 * * * cd /opt/djc-chat && docker compose exec -T postgres pg_dump -U postgres chatwoot_production | gzip > /opt/djc-chat/backups/db-$(date +\%F).sql.gz
```

### Logs / restart

```bash
docker compose logs -f rails
docker compose restart rails sidekiq
```

---

## 8. Troubleshooting

| Symptom | Check |
|---|---|
| 502 Bad Gateway | `docker compose logs rails` — boot failure or missing `SECRET_KEY_BASE` |
| TLS cert fails | DNS not propagated, or 80/443 blocked by `ufw` |
| Emails don't send | `docker compose logs sidekiq`; verify SMTP creds + port 587 + STARTTLS |
| `db:chatwoot_prepare` fails | Postgres not ready — wait 30s and retry |
| OOM during boot | Droplet too small — resize to 4GB+ |

---

## 9. Deferred to later phases

- **Branding** (Phase 3) — `INSTALLATION_NAME`, `BRAND_NAME`, logo/favicon swap
- **DigitalOcean Spaces** for attachments — set `ACTIVE_STORAGE_SERVICE=amazon`
- **Off-site backups** — push daily dump to Spaces
- **Monitoring** — UptimeRobot on `https://chat.yourdomain.com/api`
