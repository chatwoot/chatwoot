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

Protege contra perda total da VPS. Usa `rclone` para enviar dumps para
B2/R2/S3 e envia alertas em caso de falha.

1. Instalar rclone: `curl https://rclone.org/install.sh | sudo bash`
2. Configurar remote: `rclone config` (criar remote chamado `offsite`)
3. Testar manualmente: `./scripts/backup_offsite.sh`
4. Agendar no cron:

```bash
# /etc/cron.d/synapseos-backup
0 3 * * * root ALERT_EMAIL=ops@dexidigital.com.br ALERT_SLACK_WEBHOOK=https://hooks.slack.com/... /opt/synapseos-core/scripts/backup_offsite.sh >> /var/log/synapseos-backup.log 2>&1
```

Variáveis de ambiente do script:

| Variável | Default | Descrição |
|---|---|---|
| `RCLONE_REMOTE` | `offsite` | Nome do remote no rclone |
| `RCLONE_BUCKET` | `synapseos-backups` | Bucket/container no remote |
| `BACKUP_RETENTION` | `30` | Dias pra manter backups antigos |
| `ALERT_EMAIL` | — | Email pra alerta de falha |
| `ALERT_SLACK_WEBHOOK` | — | Webhook do Slack pra alerta de falha |

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
