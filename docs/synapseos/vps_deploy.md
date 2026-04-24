# Deploy em VPS (modelo Interlivre)

Guia pra subir o Synapse OS numa VPS dedicada por cliente. Stack completa
(web + worker + Postgres + Redis) via Docker Compose, com volume local
pra storage — **mídia outbound funciona sem S3**.

## Requisitos mínimos

- Ubuntu 22.04+ / Debian 12 (ou equivalente com Docker)
- 4 vCPU, 8 GB RAM, 50 GB SSD (escala pra 100+ agentes simultâneos)
- Domínio apontado pro IP da VPS (`chatwoot.cliente.com.br`)
- Porta 80 + 443 abertas pra HTTPS

## Passos

### 1. Instalar Docker

```bash
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
newgrp docker
```

### 2. Clonar o repo

```bash
git clone https://github.com/Dexi-Digital/synapseos-core.git
cd synapseos-core
```

### 3. Configurar `.env`

```bash
cp .env.example.prod .env
openssl rand -hex 64   # gera SECRET_KEY_BASE
openssl rand -hex 16   # gera POSTGRES_PASSWORD
openssl rand -hex 16   # gera REDIS_PASSWORD
```

Edite `.env` preenchendo:
- `SECRET_KEY_BASE`
- `POSTGRES_PASSWORD`
- `REDIS_PASSWORD`
- `REDIS_URL=redis://:<senha>@redis:6379`
- `FRONTEND_URL=https://chatwoot.cliente.com.br`
- SMTP (opcional mas recomendado)

### 4. Subir a stack

```bash
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d
```

### 5. Primeira inicialização do banco

```bash
docker compose -f docker-compose.prod.yml run --rm web bundle exec rails db:chatwoot_prepare
```

Cria schema + todos os seeders (AccountDefaults roda automaticamente na
criação da primeira conta via wizard).

### 6. Proxy reverso (Caddy exemplo)

Instale Caddy na VPS:

```bash
sudo apt install -y caddy
```

Edite `/etc/caddy/Caddyfile`:

```
chatwoot.cliente.com.br {
    reverse_proxy localhost:3000
}
```

Caddy gera SSL via Let's Encrypt automaticamente. Reload:

```bash
sudo systemctl reload caddy
```

### 7. Criar primeira conta

Acesse `https://chatwoot.cliente.com.br` → wizard cria account + admin.
Na criação, o `AccountDefaults.seed` dispara automaticamente:
- 5 pipeline stages default
- 12 labels do contrato (outbound, lead_qualificado, etc.)
- 7 AgentBots do esquadrão (Alice, Iza, Luís, Otto, Fernanda, Ângela, Vitor)
- Custom attributes do painel "Dados do Sistema Legado"

## Upgrade

Sempre testar em staging primeiro. Na VPS:

```bash
cd synapseos-core
git pull
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d
```

Se houver nova migration, ela roda automaticamente via release phase do
Dockerfile (`db:chatwoot_prepare`).

## Backup

Postgres:

```bash
docker compose -f docker-compose.prod.yml exec postgres \
  pg_dump -U postgres chatwoot_production | gzip > backup_$(date +%F).sql.gz
```

Storage (attachments):

```bash
docker run --rm -v synapseos-core_storage:/data \
  -v $PWD:/backup alpine tar czf /backup/storage_$(date +%F).tar.gz -C /data .
```

Rotacione com cron em `/etc/cron.daily/`.

## Troubleshooting

| Sintoma | Provável causa | Fix |
|---|---|---|
| 502 Bad Gateway no Caddy | `web` container não subiu | `docker compose logs web` |
| Mídia outbound não chega | Volume `storage` não compartilhado | Verificar que web e worker têm `- storage:/app/storage` |
| Sidekiq não processa jobs | Container `worker` caído | `docker compose restart worker` |
| `PG::ConnectionBad` | Postgres bind do healthcheck errado | Verificar `POSTGRES_PASSWORD` no `.env` |
| Avisa webhook 401 | `FRONTEND_URL` não bate com registro na Avisa | Atualizar inbox → wizard re-registra webhook |

## Especificidades Synapse OS

- **Storage compartilhado** (`storage:/app/storage`) é crítico pra mídia outbound funcionar. Não troque pra bind mount sem repassar o volume aos dois serviços.
- **Sidekiq worker** é **obrigatório** rodando — `SendReplyJob` (WhatsApp), `AgentBotJob`, seeders async, tudo depende dele.
- **pgvector/pg14** é a imagem oficial pra pgvector — necessária pro módulo Captain/embeddings, ainda que desativado por padrão no nav.
