---
name: witdev-project-setup
description: Setup completo de novo projeto WitDev Stack — scaffolding de Next.js 16 + PostgreSQL 17/pgvector + Redis 8 + Docker + Prisma + scripts padronizados (dev.sh, build.sh, db-prepare.js). Use quando criar um projeto do zero, configurar ambiente de dev, ou bootstrapar infraestrutura Docker segundo os padrões WitDev.
license: MIT
metadata:
  author: wital
  version: "1.0.0"
---

# WitDev Project Setup — Skill

Guia canônico para criar e configurar novos projetos com a stack WitDev padrão. Garante consistência entre todos os projetos em termos de versões, scripts, estrutura Docker e fluxo de deploy.

---

## Stack Pinada (Março 2026)

| Tecnologia | Versão / Imagem | Justificativa |
|---|---|---|
| PostgreSQL + pgvector | `pgvector/pgvector:pg17` | pgvector 0.8.x já incluso |
| Redis | `redis:8-alpine` | Major pin, patches automáticos, ~15MB |
| Node.js | `node:24-alpine` | LTS "Krypton", suporte até Abr/2028 |
| Next.js | `next@^16.1.x` | Turbopack estável, React 19.2 |
| Prisma | latest compatible | ORM padrão — migrate deploy em prod |
| BullMQ | latest | Filas Redis |
| NextAuth.js | v5 + Prisma adapter | Auth padrão |

> **Regra de versão:** nunca use `latest` para banco/cache (pode quebrar com major). Use `redis:8-alpine`, não `redis:latest` nem `redis:8.6.1`.

---

## Estrutura de Diretórios

```
meu-projeto/
├── app/                        # Next.js App Router
│   ├── api/                    # API Routes
│   └── (pages)/
├── lib/                        # Utilities core (db, auth, redis, etc.)
├── components/                 # React components
├── services/                   # Business logic
├── worker/                     # Background jobs (BullMQ)
├── prisma/
│   ├── schema.prisma
│   └── migrations/             # SEMPRE commitado com o schema
├── scripts/
│   └── db-prepare.js           # Bootstrap DB no startup
├── docker-compose-dev.yml
├── docker-compose-producao.yaml
├── Dockerfile.prod
├── dev.sh                      # Gerenciador do ambiente de dev
├── build.sh                    # Build + Push + Deploy prod
├── .env.example
├── .env.development            # Ignorado pelo git
├── .env.local                  # Ignorado pelo git (contém Portainer, etc.)
├── biome.json                  # Lint/format
├── package.json
├── tsconfig.json
└── CLAUDE.md / AGENTS.md      # Contexto para AI agents
```

---

## Workflow: Criar Novo Projeto

### Passo 1 — Scaffolding Next.js

```bash
npx create-next-app@latest meu-projeto \
  --typescript --tailwind --eslint --app --src-dir --no --import-alias "@/*"
cd meu-projeto
```

### Passo 2 — Dependências

```bash
pnpm add @prisma/client bullmq redis next-auth@5 @auth/prisma-adapter \
  @t3-oss/env-nextjs zod sonner
pnpm add -D prisma @biomejs/biome typescript @types/node @types/react
```

### Passo 3 — Docker Compose Dev

```yaml
# docker-compose-dev.yml
services:
  postgres:
    image: pgvector/pgvector:pg17
    environment:
      POSTGRES_USER: app_user
      POSTGRES_PASSWORD: app_password_dev
      POSTGRES_DB: app_db
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U app_user -d app_db"]
      interval: 5s
      timeout: 5s
      retries: 10

  redis:
    image: redis:8-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 3s
      retries: 10

  app:
    build:
      context: .
      dockerfile: Dockerfile.dev
    working_dir: /app
    volumes:
      - .:/app
      - node_modules:/app/node_modules
    ports:
      - "3000:3000"
    env_file:
      - .env.development
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy

  worker:
    build:
      context: .
      dockerfile: Dockerfile.dev
    working_dir: /app
    volumes:
      - .:/app
      - node_modules:/app/node_modules
    env_file:
      - .env.development
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    command: pnpm run worker

volumes:
  node_modules:
  postgres_data:
  redis_data:
```

> **Nota volumes:** `node_modules` é volume Docker isolado do host. Postgres e Redis são persistentes. Não crie volume separado para `.next`.

### Passo 4 — Script `scripts/db-prepare.js`

Script Node.js executado no startup (dentro e fora do container) que:
1. Aguarda o Postgres estar disponível (retry loop)
2. Cria o database se não existir
3. Habilita a extensão `vector` (pgvector)
4. Roda `prisma migrate deploy` ou `prisma db push` conforme o modo
5. (Opcional) Roda seed

```js
#!/usr/bin/env node
"use strict";
// Carrega .env conforme NODE_ENV
const fs = require("fs"), path = require("path"), { execSync } = require("child_process");
const envFiles = process.env.NODE_ENV === "production"
  ? [".env.production", ".env"]
  : [".env.development", ".env.local", ".env"];
for (const f of envFiles) {
  const p = path.join(process.cwd(), f);
  if (fs.existsSync(p)) { require("dotenv").config({ path: p }); break; }
}

const { PrismaClient } = require("@prisma/client");
const MODE = process.argv.includes("--mode=deploy") ? "deploy" : "reset";
const RETRIES = 60, SLEEP_MS = 2000;
const sleep = ms => new Promise(r => setTimeout(r, ms));

async function waitDB(prisma) {
  for (let i = 1; i <= RETRIES; i++) {
    try { await prisma.$connect(); await prisma.$disconnect(); return; }
    catch (e) { console.log(`⏳ Aguardando Postgres (${i}/${RETRIES})...`); await sleep(SLEEP_MS); }
  }
  throw new Error("Postgres não disponível após timeout");
}

async function main() {
  const prisma = new PrismaClient();
  await waitDB(prisma);
  // Habilitar pgvector
  await prisma.$executeRawUnsafe("CREATE EXTENSION IF NOT EXISTS vector");
  console.log("✅ pgvector habilitado");
  // Aplicar migrations
  const prismaBin = fs.existsSync("node_modules/.bin/prisma") ? "node_modules/.bin/prisma" : "prisma";
  execSync(`${prismaBin} migrate deploy`, { stdio: "inherit" });
  console.log("✅ Migrations aplicadas");
  await prisma.$disconnect();
}

main().catch(e => { console.error("❌ db-prepare falhou:", e); process.exit(1); });
```

**Variáveis de ambiente do db-prepare:**

| Variável | Default | Descrição |
|---|---|---|
| `DB_CONNECT_RETRIES` | `60` | Tentativas de conexão |
| `DB_CONNECT_SLEEP_MS` | `2000` | Intervalo entre tentativas (ms) |
| `PRISMA_RUN_SEED` | `false` | Rodar seed após migration |
| `VECTOR_REQUIRED` | `true` | Falhar se pgvector não disponível |
| `EMBEDDING_DIMS` | `1536` | Dimensões do vetor (OpenAI = 1536) |

### Passo 5 — `dev.sh`

Script bash que gerencia o ciclo completo de dev. Padrão obrigatório:

```bash
#!/usr/bin/env bash
# dev.sh - Gerenciador do ambiente de desenvolvimento
# Uso: ./dev.sh         → sobe tudo
#      ./dev.sh -n      → sobe tudo + ngrok
#      ./dev.sh build   → rebuild incremental
#      ./dev.sh build --no-cache    → rebuild limpo
#      ./dev.sh down    → para containers
#      ./dev.sh logs [service]      → ver logs
#      ./dev.sh shell   → abre shell no container app
#      ./dev.sh prisma  → Prisma Studio
set -euo pipefail
```

**Funções obrigatórias no dev.sh:**
- `ensure_env_file` — copia `.env.example` → `.env.development` se não existir
- `ensure_network` — cria rede Docker externa (`minha_rede`) se não existir
- `dc()` — wrapper Docker Compose (suporta v1 e v2)
- `cmd_up` — sobe + tail logs + trap Ctrl+C para graceful stop
- `cmd_build` — para containers → remove volume `node_modules` → rebuild → sobe → gera Prisma Client → roda migrations
- `cmd_logs [service] [tar|cat]` — logs com opções de exportar/compactar
- `print_urls` — exibe URLs do app, infraestrutura e comandos úteis

**Cores padronizadas:**
```bash
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
log_info()    { echo -e "${BLUE}ℹ${NC}  $1"; }
log_success() { echo -e "${GREEN}✔${NC}  $1"; }
log_warn()    { echo -e "${YELLOW}⚠${NC}  $1"; }
log_error()   { echo -e "${RED}✖${NC}  $1"; }
log_header()  { echo -e "\n${BOLD}${CYAN}═══ $1 ═══${NC}\n"; }
```

### Passo 6 — `build.sh` (Produção)

Script de build + push Docker Hub + deploy automático via Portainer:

```bash
# Uso:
./build.sh              # build, push latest, force-update prod
./build.sh v1.2.3       # build, push e tag v1.2.3
./build.sh --no-deploy  # só build + push, sem atualizar prod
```

**Fluxo obrigatório:**
1. Verificar e iniciar Postgres local para build SSG (Next.js precisa do DB no build)
2. `docker compose build app`
3. Tag da imagem
4. `docker push` (latest + versão se diferente)
5. Sleep 5s para propagação no registry
6. Force-update de serviços Swarm via Portainer Docker Proxy API

**Ordem de update dos serviços:** Worker ANTES da App (evita race condition BullMQ).

**Portainer config em `.env.local`:**
```
PORTAINER_URL=https://portainer.witdev.com.br
PORTAINER_API_KEY=ptr_xxxxxxxxxxxx
PORTAINER_ENDPOINT_ID=1
```

---

## Banco de Dados — Regras Obrigatórias

```bash
# ✅ DEV: criar migration
pnpm exec prisma migrate dev --name descricao

# ✅ PROD: aplicar migrations pendentes
pnpm exec prisma migrate deploy

# ❌ NUNCA usar (destroem histórico e causam drift):
# prisma db pull
# prisma db push
```

**Drift em DEV** (aceitável resetar):
```bash
pnpm exec prisma migrate reset --force   # DEV ONLY
pnpm exec prisma migrate dev --name fix
```

> A pasta `prisma/migrations/` SEMPRE deve ser commitada junto com `schema.prisma`.

---

## Lib Redis Singleton (`lib/redis.ts`)

```typescript
import { createClient, type RedisClientType } from "redis";

const globalForRedis = globalThis as unknown as { redis?: RedisClientType };

function getRedisClient(): RedisClientType {
  if (!globalForRedis.redis) {
    const client = createClient({ url: process.env.REDIS_URL || "redis://localhost:6379" });
    client.on("error", (err) => console.error("Redis error:", err));
    client.connect();
    globalForRedis.redis = client as RedisClientType;
  }
  return globalForRedis.redis;
}

export const redis = getRedisClient();
```

---

## Dockerfile.prod (Padrão Multi-Stage)

```dockerfile
# ── Build ──────────────────────────────────────────────────────────────────
FROM node:24-alpine AS builder
WORKDIR /app

# Install deps separado para aproveitar cache
COPY package.json pnpm-lock.yaml ./
RUN corepack enable && pnpm install --frozen-lockfile

COPY . .

# Precisa do DB disponível para prisma generate + SSG
ARG DATABASE_URL
ENV DATABASE_URL=$DATABASE_URL
RUN pnpm exec prisma generate
RUN pnpm run build

# ── Runtime ────────────────────────────────────────────────────────────────
FROM node:24-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production

COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public
COPY --from=builder /app/scripts ./scripts
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=builder /app/node_modules/@prisma ./node_modules/@prisma

EXPOSE 3000
CMD ["sh", "-c", "node scripts/db-prepare.js --mode=deploy && node server.js"]
```

---

## `.env.example` Mínimo

```bash
# Database
DATABASE_URL=postgresql://app_user:app_password_dev@localhost:5432/app_db

# Redis
REDIS_URL=redis://localhost:6379

# Auth
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=change-me-in-production

# App
NEXT_PUBLIC_APP_URL=http://localhost:3000

# Portainer (só em .env.local, não commitado)
# PORTAINER_URL=https://portainer.witdev.com.br
# PORTAINER_API_KEY=ptr_xxxxxxxxxxxx
# PORTAINER_ENDPOINT_ID=1
```

---

## `package.json` — Scripts Padrão

```json
{
  "scripts": {
    "dev": "next dev --turbopack",
    "build": "next build",
    "start": "next start",
    "lint": "biome check .",
    "lint-apply": "biome check --write .",
    "format-apply": "biome format --write .",
    "worker": "tsx watch worker/index.ts",
    "start:worker": "node dist/worker/index.js",
    "db:prepare": "node scripts/db-prepare.js",
    "db:generate": "prisma generate",
    "db:studio": "prisma studio",
    "db:migrate": "prisma migrate dev",
    "db:seed": "prisma db seed",
    "type-check": "tsc --noEmit && tsc --noEmit -p tsconfig.worker.json"
  }
}
```

---

## Checklist de Novo Projeto

```
□ npx create-next-app@latest com --typescript --tailwind --app
□ Instalar dependências base (pnpm add ...)
□ docker-compose-dev.yml com pgvector:pg17 + redis:8-alpine + healthchecks
□ .env.example com DATABASE_URL, REDIS_URL, NEXTAUTH_SECRET
□ scripts/db-prepare.js com retry + ensure extension + migrate deploy
□ lib/db.ts (pool pg singleton) ou Prisma singleton
□ lib/redis.ts (redis client singleton)
□ dev.sh com todos os comandos padronizados (up/build/down/logs/shell/prisma)
□ build.sh com multi-step: postgres start → build → push → Portainer deploy
□ Dockerfile.prod multi-stage node:24-alpine
□ biome.json configurado
□ CLAUDE.md / AGENTS.md com contexto do projeto
□ prisma/schema.prisma com provider = "postgresql" + previewFeatures = ["postgresqlExtensions"]
□ Testar: ./dev.sh → app em localhost:3000 sem erros
□ Verificar pgvector: SELECT * FROM pg_extension WHERE extname = 'vector';
□ Verificar Redis: docker exec <container> redis-cli ping → PONG
□ type-check: pnpm exec tsc --noEmit
```

---

## Comandos Úteis (Referência Rápida)

```bash
# Dev
./dev.sh                           # sobe tudo
./dev.sh -n                        # sobe tudo + ngrok
./dev.sh build                     # rebuild incremental ⚡
./dev.sh build --no-cache          # rebuild limpo 🐌
./dev.sh logs                      # todos os logs
./dev.sh logs worker               # logs do worker (tempo real)
./dev.sh logs worker tar           # compactar logs do worker
./dev.sh shell                     # shell no container app
./dev.sh prisma                    # Prisma Studio

# DB
pnpm exec prisma migrate dev --name X  # ✅ criar migration (dev)
pnpm exec prisma migrate deploy        # ✅ aplicar em prod
pnpm exec prisma generate              # regenerar client
pnpm exec prisma studio                # GUI do banco

# Produção
./build.sh                         # build + push + deploy
./build.sh v1.2.3                  # build + push tag + deploy
./build.sh --no-deploy             # só build + push

# TypeScript
pnpm exec tsc --noEmit && pnpm exec tsc --noEmit -p tsconfig.worker.json

# Docker Prod (SSH)
docker service ls
docker service logs socialwise_app --tail 200
docker service logs socialwise_worker --tail 200
```

---

## Conexões em Docker — Evitando "Conexão Fantasma"

### O Problema

Em Docker/Swarm, a tabela NAT do bridge network (`nf_conntrack`) descarta conexões TCP idle silenciosamente (~30min). O app acha que a conexão com Postgres ainda existe, manda uma query, e recebe timeout → **conexão fantasma**.

### O que NÃO funciona

**TCP keepalive na connection string do Prisma:**
```
DATABASE_URL=postgresql://...?tcp_keepalive=1&tcp_keepalive_idle=120&tcp_keepalive_interval=10
```
O Prisma usa um query engine em Rust, não o driver `pg` do Node.js. Parâmetros `tcp_keepalive_idle` e `tcp_keepalive_interval` são **ignorados silenciosamente**. Prisma só entende `connect_timeout`, `pool_timeout` e `socket_timeout` na URL.

### A Solução Correta (por camada)

Cada driver tem capacidades diferentes — a solução depende de qual você usa:

| Driver | TCP keepalive nativo? | Solução |
|---|---|---|
| **pg.Pool** (Node.js) | **Sim** — `keepAlive: true` | 2 linhas, zero overhead, o OS cuida |
| **ioredis** | **Sim** — `keepAlive: 10000` | 1 linha |
| **Prisma + Driver Adapter** (`@prisma/adapter-pg`) | **Sim** — usa pg.Pool por baixo | Adapter + `keepAlive: true`, sem heartbeat |
| **Prisma engine Rust** (padrão) | **Não** — sem config exposta | Heartbeat `SELECT 1` a cada 4min (workaround) |

**1. pg Pool direto — TCP keepalive no nível do socket (SOLUÇÃO IDEAL):**
```typescript
import pg from "pg";
const pool = new pg.Pool({
  connectionString: process.env.DATABASE_URL,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
  keepAlive: true,                    // ← TCP keepalive ativa
  keepAliveInitialDelayMillis: 10000, // ← primeiro keepalive após 10s idle
});
```
O `pg` do Node configura o socket TCP diretamente. O OS envia pacotes periódicos que mantêm a entrada na tabela NAT e detectam conexões mortas. **Sem queries fake, sem overhead, sem intervalo.**

**2. Prisma — Duas opções:**

O Prisma query engine padrão é escrito em Rust e gerencia seu próprio pool de conexões. **Não existe** config para TCP keepalive nos sockets que ele abre. Sem o Rust engine, o Prisma fica refém das configs globais do OS do container.

**Opção A — Driver Adapter `@prisma/adapter-pg` (solução ideal, Prisma 5+):**

Usa o driver `pg` do Node.js em vez do engine Rust. Com isso, `keepAlive: true` funciona nativamente — **sem heartbeat**.

```bash
pnpm add @prisma/adapter-pg pg
```

```prisma
// schema.prisma
generator client {
  provider        = "prisma-client-js"
  previewFeatures = ["driverAdapters"]
}
```

```typescript
// lib/prisma.ts — Com Driver Adapter (sem heartbeat!)
import { PrismaClient } from "@prisma/client";
import { PrismaPg } from "@prisma/adapter-pg";
import pg from "pg";

const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };

if (!globalForPrisma.prisma) {
  const pool = new pg.Pool({
    connectionString: process.env.DATABASE_URL,
    max: 20,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 5000,
    keepAlive: true,                    // ← TCP keepalive nativo!
    keepAliveInitialDelayMillis: 10000,
  });
  const adapter = new PrismaPg(pool);
  globalForPrisma.prisma = new PrismaClient({ adapter });
}

export const prisma = globalForPrisma.prisma;
```

**Opção B — Engine Rust padrão + Heartbeat (workaround, se não puder usar adapter):**

```typescript
// lib/prisma.ts — Singleton com heartbeat
import { PrismaClient } from "@prisma/client";

const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };

export const prisma = globalForPrisma.prisma ?? new PrismaClient({
  log: process.env.NODE_ENV === "production" ? ["error"] : ["error", "warn"],
});

if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma;

// Heartbeat — mantém conexão viva na tabela NAT do Docker
// Necessário porque o engine Rust do Prisma não expõe TCP keepalive
const HEARTBEAT_MS = 4 * 60 * 1000; // 4 min (< nf_conntrack timeout ~30min)
setInterval(async () => {
  try { await prisma.$queryRaw`SELECT 1`; }
  catch { /* Prisma 5+ reconecta automaticamente no próximo uso */ }
}, HEARTBEAT_MS);
```

**Preferência:** Opção A > Opção B. O Driver Adapter elimina o heartbeat, usa TCP keepalive real do OS, e reduz overhead (sem queries fake a cada 4min). A Opção B é aceitável para projetos existentes onde migrar para adapter é arriscado.

**Connection string — somente params que o Prisma REALMENTE suporta:**
```
DATABASE_URL=postgresql://user:pass@host:5432/db?connect_timeout=10&pool_timeout=30
```

> **⚠️ NÃO use `socket_timeout` em produção** — ele mata QUALQUER query que exceda o tempo (incluindo migrations, relatórios, bulk inserts). É como "matar o paciente para curar a febre".
>
> **⚠️ `tcp_keepalive*` na URL é IGNORADO pelo Prisma padrão (engine Rust)** — ele não passa esses parâmetros pro socket. Funciona com pg.Pool e com Driver Adapter, não com o engine Rust.
>
> **⚠️ `relationMode = "prisma"` NÃO tem relação com conexão/keepalive** — serve para emular Foreign Keys via software (PlanetScale/Vitess). Não altera nada na camada de rede TCP.

**3. Redis (ioredis) — keepalive nativo + retry:**
```typescript
import Redis from "ioredis";
const redis = new Redis(process.env.REDIS_URL, {
  keepAlive: 10000,                  // TCP keepalive a cada 10s
  maxRetriesPerRequest: null,        // obrigatório para BullMQ
  retryStrategy: (times) => Math.min(times * 100, 3000),
  enableReadyCheck: true,
  lazyConnect: true,
});
```

### Anti-padrão: NÃO faça isso

- **`withPrismaReconnect()` com locks e retry manual** — Prisma 5+ reconecta automaticamente no pool. O heartbeat simples é suficiente, o wrapper de 100+ linhas duplica lógica interna.
- **Lock `__prismaConnectLock`** — `$connect()` já é serializado internamente pelo Prisma.
- **Mock Redis inline no código de produção** — separe em arquivo de teste.
- **20+ console.log com emojis** — poluem stdout em prod.

**Resumo:**
- **pg.Pool direto:** `keepAlive: true` (solução ideal, 2 linhas)
- **Prisma + Driver Adapter (`@prisma/adapter-pg`):** pg.Pool com `keepAlive: true` por baixo (solução ideal para Prisma, sem heartbeat)
- **Prisma engine Rust (padrão):** Heartbeat `SELECT 1` a cada 4min (workaround aceitável, 5 linhas)
- **ioredis:** `keepAlive: 10000` (nativo, 1 linha)
- **Todos:** Singleton via `globalThis` + graceful shutdown

---

## Decisões de Design e Gotchas

- **Ordem de update Swarm:** Worker antes do App — BullMQ pode enfileirar jobs com novo payload antes da App estar pronta.
- **Postgres no build:** Next.js SSG (page generation) precisa de conexão DB. O `build.sh` sobe o Postgres automaticamente se necessário e para ao final.
- **Volume `node_modules`:** Separado do host para evitar incompatibilidade de binários (Alpine vs host). Sempre deletado no `./dev.sh build`.
- **`redis:8-alpine` não `redis:latest`:** Major version pode mudar. Alpine para imagem mínima.
- **pgvector no Dockerfile:** Usar `pgvector/pgvector:pg17` — já vem com a extensão compilada, sem necessidade de `apt install` extra.
- **Migrations nunca via `db push` ou `db pull`** em nenhum ambiente.
- **Conexão fantasma em Docker:** Sempre usar heartbeat para Prisma e `keepAlive: true` para pg Pool. Nunca confiar em TCP keepalive via connection string do Prisma.
