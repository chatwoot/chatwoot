# Docker Compose para Desenvolvimento Local

Este documento descreve como usar Docker Compose para gerenciar dependências (PostgreSQL, Redis, MailHog) localmente.

## 🎯 Vantagens

- ✓ Não instalar PostgreSQL/Redis no host
- ✓ Ambiente isolado e limpo
- ✓ Fácil reset (delete containers/volumes)
- ✓ Mesma configuração para todo time

## 🚀 Quick Start com Docker

### 1. Iniciar Dependências

```bash
docker-compose -f docker-compose.dev.yaml up -d
```

Verificar status:

```bash
docker-compose -f docker-compose.dev.yaml ps
```

Saída esperada:

```
NAME                          STATUS
chatwoot-postgres-dev         Up (healthy)
chatwoot-redis-dev            Up (healthy)
chatwoot-mailhog-dev          Up
```

### 2. Configurar .env

```bash
cp .env.local.example .env
```

As configurações já estão corretas para Docker Compose.

### 3. Setup do Rails

```bash
bundle install
pnpm install

bundle exec rails db:create
bundle exec rails db:migrate
bundle exec rails db:seed  # opcional
```

### 4. Iniciar Dev Servers

```bash
pnpm dev
```

Pronto! A aplicação está em http://localhost:3000

---

## 🛠️ Comandos Úteis

### Serviços Docker

```bash
# Iniciar
docker-compose -f docker-compose.dev.yaml up -d

# Parar
docker-compose -f docker-compose.dev.yaml down

# Ver logs
docker-compose -f docker-compose.dev.yaml logs -f postgres
docker-compose -f docker-compose.dev.yaml logs -f redis
docker-compose -f docker-compose.dev.yaml logs -f mailhog

# Entrar no container PostgreSQL
docker-compose -f docker-compose.dev.yaml exec postgres psql -U postgres -d chatwoot_dev

# Entrar no Redis
docker-compose -f docker-compose.dev.yaml exec redis redis-cli
```

### Banco de Dados

```bash
# Criar banco
bundle exec rails db:create

# Migrar
bundle exec rails db:migrate

# Resetar banco (apaga dados!)
bundle exec rails db:reset

# Seed de dados
bundle exec rails db:seed
```

### MailHog

Acessar interface web para ver emails enviados:

- URL: http://localhost:8025

---

## 🔧 Troubleshooting Docker

### Porta já está em uso

```bash
# Encontrar qual processo
lsof -i :5432   # PostgreSQL
lsof -i :6379   # Redis
lsof -i :1025   # MailHog SMTP
lsof -i :8025   # MailHog Web

# Matar processo
kill -9 <PID>
```

### Containers não iniciam

```bash
# Ver logs detalhados
docker-compose -f docker-compose.dev.yaml logs postgres

# Reconstruir
docker-compose -f docker-compose.dev.yaml down -v
docker-compose -f docker-compose.dev.yaml up -d
```

### Reset completo

```bash
# Parar e remover tudo (volumes e containers)
docker-compose -f docker-compose.dev.yaml down -v

# Reiniciar
docker-compose -f docker-compose.dev.yaml up -d

# Recriar banco
bundle exec rails db:create db:migrate
```

### Verificar conectividade

```bash
# PostgreSQL
psql -h localhost -U postgres -d chatwoot_dev -c "SELECT version();"

# Redis
redis-cli -h localhost PING

# SMTP
telnet localhost 1025
```

---

## 🏠 Opção: Localhost Nativo (Sem Docker)

Se preferir instalar PostgreSQL/Redis localmente:

1. Instale PostgreSQL 16 e Redis conforme seu SO
2. Use `.env` (já incluso) com `POSTGRES_HOST=localhost` e `REDIS_URL=redis://localhost:6379`
3. Siga os passos normais de setup

---

## 📊 Volumes Docker

Docker Compose cria volumes para persistência:

- `postgres-dev`: Dados do PostgreSQL
- `redis-dev`: Dados do Redis

Para limpar:

```bash
docker-compose -f docker-compose.dev.yaml down -v
```

---

## 🔐 Segurança (Dev Only)

⚠️ **AVISO**: Senhas padrão são apenas para desenvolvimento!

- PostgreSQL: `postgres/postgres`
- Redis: sem senha

Nunca use essas credenciais em produção.

---

## 📚 Próximas Ações

1. ✓ Contenedores rodando: `docker-compose -f docker-compose.dev.yaml ps`
2. ✓ .env configurado: `cat .env | grep POSTGRES`
3. ✓ Rails setup: `bundle exec rails db:migrate`
4. ✓ Dev servers: `pnpm dev`
5. ✓ Acessar: http://localhost:3000

---

Para dúvidas, consulte [README_SETUP_LOCAL.md](README_SETUP_LOCAL.md) ou [QUICKSTART.md](QUICKSTART.md).
