# ADR-0007: Deploy on a single VPS with Docker Compose + Caddy (Coolify-compatible)

- **Status:** Accepted
- **Date:** 2026-06-15
- **Deciders:** Omni-Chat-AI core

## Context
We need a deploy target that is cheap, simple to operate solo, and honours a preference for a
PaaS-like (Railway/Render) experience. The stack is many **stateful** services — Postgres,
Redis, Qdrant, ClickHouse, and Chatwoot web+worker — plus several stateless ones.

## Decision
Target a **single VPS running Docker Compose**, fronted by **Caddy** for automatic HTTPS, with a
one-command `deploy.sh` that generates all infra secrets and brings the stack up. The same
`docker-compose.yml` is **Coolify-compatible**, so an operator who wants a dashboard can run
Coolify on the same VPS and import the compose for click-to-deploy UX.

## Consequences
- **Positive:** co-locates stateful services (trivial volumes/backups), lowest cost (~one
  machine), one command to stand up, automatic TLS. Coolify gives PaaS feel without splitting
  services across billed instances.
- **Negative:** single-host (vertical scaling first); the operator manages OS/Docker updates.
- **Follow-ups:** optional managed Postgres/Redis for HA; a Caddy service in-compose for
  fully containerised TLS.

## Alternatives considered
- Railway/Render multi-service → rejected for this stack: each stateful service becomes a
  separate billed instance and ClickHouse/Qdrant are awkward there; cost and ops grow fast.
- Kubernetes → rejected: massive operational overhead for a solo/SMB deployment.
