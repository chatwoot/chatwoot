# 🚀 Deploying Chatwoot from Source

This document outlines the process to build, run, and deploy a custom Chatwoot stack from source using your `docker-compose.production.yaml` file.

---

## 1. 🧱 Build the Base Image

Build the base image (defined in your Dockerfile) before anything else:

```bash
docker compose -f docker-compose.production.yaml build base
````

---

## 2. 🐳 Build Full Application Stack

Build the remaining containers (app, sidekiq, redis, postgres, etc.):

```bash
docker compose -f docker-compose.production.yaml build
```

---

## 3. 🛠 Prepare the Database

Run the database setup and any required migrations:

```bash
docker compose -f docker-compose.production.yaml run --rm rails bundle exec rails db:chatwoot_prepare
```

This step:

* Removes stale PIDs and cache
* Waits for PostgreSQL to be ready
* Runs migrations and seed logic

---

## 4. 📦 Bring Everything Up

Start all services:

```bash
docker compose -f docker-compose.production.yaml up
```

You can now access your services:

* Chatwoot App: [http://localhost:3000](http://localhost:3000)
* PostgreSQL: `postgres://postgres:password@localhost:5432`
* Redis: `redis://localhost:6379`

> Customize ports or env vars in `.env` and your compose file if needed.

---

## 5. 🚢 Deploying to Docker Hub

To publish your custom app container:

```bash
# Tag the built image
docker tag chatwoot:latest vegavision/chatwoot:latest

# Log in to Docker Hub (if not already)
docker login

# Push the image to your repository
docker push vegavision/chatwoot:latest
```

---

## ✅ Summary

This deployment flow supports:

* Local development and testing
* Running Chatwoot with a dedicated `production.yaml` file
* Database persistence via volumes
* Backups and rebuilds without data loss
* Containerized image deployment to Docker Hub

