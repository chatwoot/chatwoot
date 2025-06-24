# 🚀 Production Deployment Guide

This document outlines how to deploy the **Chatwoot** application in a production environment using a prebuilt image (`vegavision:latest`), Docker Compose, and your custom configuration.

---

## 1. 🧾 Sample `docker-compose.production.yaml`

Here's a minimal production-ready example:

```yaml
version: "3.8"

services:
  postgres:
    image: postgres:14
    container_name: chatwoot-postgres
    restart: always
    volumes:
      - pgdata:/var/lib/postgresql/data
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: your_password
      POSTGRES_DB: chatwoot

  redis:
    image: redis:7
    container_name: chatwoot-redis
    restart: always

  rails:
    image: vegavision/chatwoot:latest
    container_name: chatwoot
    depends_on:
      - postgres
      - redis
    environment:
      RAILS_ENV: production
      POSTGRES_HOST: postgres
      POSTGRES_USERNAME: postgres
      POSTGRES_PASSWORD: your_password
      REDIS_URL: redis://redis:6379
    ports:
      - "3000:3000"

  sidekiq:
    image: vegavision/chatwoot:latest
    container_name: chatwoot-sidekiq
    command: bundle exec sidekiq
    depends_on:
      - postgres
      - redis
    environment:
      RAILS_ENV: production
      POSTGRES_HOST: postgres
      POSTGRES_USERNAME: postgres
      POSTGRES_PASSWORD: your_password
      REDIS_URL: redis://redis:6379

volumes:
  pgdata:
````

> Customize secrets or environment variables via `.env.production` or inline.

---

## 2. 🏗 Build Stack Using Prebuilt Image

No need to build from source — just ensure Docker pulls your tagged production image:

```bash
docker pull vegavision/chatwoot:latest
```

You can also rebuild locally if you have changes:

```bash
docker compose -f docker-compose.production.yaml build
```

---

## 3. 🛠 Prepare the Database

Run the database setup with:

```bash
docker compose -f docker-compose.production.yaml run --rm rails bundle exec rails db:chatwoot_prepare
```

This will:

* Apply migrations
* Seed required defaults
* Validate database connectivity

---

## 4. 🚀 Launch the Application

Bring everything up with:

```bash
docker compose -f docker-compose.production.yaml up -d
```

You can now access:

* **Web Interface**: [http://localhost:3000](http://localhost:3000)
* **Admin Interface**: Login using seeded admin account (check logs if unsure)

---

## ✅ Summary

This production deployment uses:

* **Prebuilt Docker image**: `vegavision/chatwoot:latest`
* **Compose-managed stack**: PostgreSQL, Redis, App, Sidekiq
* **Custom volume support** for persistent Postgres data
* **Secure and repeatable deployment flow**

For added production hardening:

* Use a reverse proxy (Nginx or Traefik)
* Enable HTTPS with certbot or a proxy
* Connect to an external managed PostgreSQL database (optional)
