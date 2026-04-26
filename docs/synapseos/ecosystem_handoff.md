# Synapse OS — Handoff Ecossistema (DevOps)

Documento mestre de entrega para o time de infraestrutura. Cobre **todo o
ecossistema** Synapse OS numa VPS dedicada por cliente (modelo Interlivre):
Chatwoot fork + Synapseos Agentic + Dexi Gateway + n8n + storage externo +
backups. Para deep-dive em cada componente, ver os docs referenciados.

**Modelo:** 1 VPS por cliente. Single-host Docker Compose. Multi-serviço
isolado por profile pra ativar/desativar conforme contrato.

---

## 1. Componentes do ecossistema

| Componente | Função | Repo | Obrigatório? |
|---|---|---|---|
| **Chatwoot fork** (synapseos-core) | Painel de atendimento WhatsApp + Super Admin | `Dexi-Digital/synapseos-core` | ✅ Sim |
| **Synapseos Agentic** | Painel de provisionamento de agentes n8n (Natália, Otto, etc.) | `dexidigital/synapseos-agentic` | Opcional (cliente que usa agentes IA) |
| **Dexi Gateway** | Ingestão multi-canal de leads (Meta/Google/Site/WhatsApp Cloud) → Syonet CRM | `services/dexi-gateway/` (dentro do core) | Opcional (cliente com portais de captação) |
| **n8n** | Orquestração dos workflows que o Agentic provisiona | self-hosted | Obrigatório se Agentic ativado |
| **Cloudflare R2** | Storage de anexos (imagens/áudios/vídeos do WhatsApp) | externo | ✅ Sim em prod |
| **Caddy** | Reverse proxy + SSL automático | host | ✅ Sim |
| **Postgres + Redis** | Banco e fila do Chatwoot | container | ✅ Sim |

```
┌───────────────────────── VPS do cliente (Ubuntu 22.04+) ─────────────────────┐
│                                                                              │
│   Caddy :443 ─────────────────────────────────────────────────────────       │
│      ├── chatwoot.cliente.com.br/         → Chatwoot web :3000               │
│      ├── chatwoot.cliente.com.br/_agentic/ → Agentic panel :8000 (opt-in)    │
│      └── gateway.cliente.com.br/           → Dexi Gateway :8080 (opt-in)     │
│                                                                              │
│   Docker Compose stack:                                                      │
│     - chatwoot-web + chatwoot-worker (mesmo image, processo diferente)       │
│     - chatwoot-postgres (pgvector/pg14)                                      │
│     - chatwoot-redis (7-alpine)                                              │
│     - synapseos-agentic         [profile: agentic]                           │
│     - dexi-gateway-api/worker   (compose próprio em services/dexi-gateway/)  │
│     - n8n                       [profile: n8n] OU container separado         │
│                                                                              │
│   Storage externo:                                                           │
│     - Cloudflare R2 → ACTIVE_STORAGE_SERVICE=s3_compatible (anexos WhatsApp) │
│                                                                              │
│   Backup:                                                                    │
│     - rclone diário pra B2/R2/S3 (pg_dump + tar de YAMLs do agentic)         │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Requisitos da máquina

| Recurso | Mínimo | Recomendado | Notas |
|---|---|---|---|
| CPU | 4 vCPU | 8 vCPU | +1 vCPU se Agentic ativo, +1 se Gateway ativo |
| RAM | 8 GB | 16 GB | +1 GB por serviço opcional |
| Disco | 50 GB SSD | 100 GB NVMe | Storage de anexos é externo (R2) — disco serve só pra Postgres + logs |
| SO | Ubuntu 22.04 | Ubuntu 24.04 LTS | |
| Portas abertas | 80, 443 | 80, 443, 22 (SSH) | Postgres/Redis/agentic/gateway ficam internos |

Cliente Interlivre exemplo (Chatwoot + Agentic + 7 agentes IA via n8n):
**8 vCPU / 16 GB / 100 GB NVMe** confortável.

---

## 3. Acessos que Lorrayne precisa pra operar sem DevOps

### 3.1 Repos GitHub
- `Dexi-Digital/synapseos-core` — write access ✅ (já tem)
- `dexidigital/synapseos-agentic` — write access ✅ (já tem)
- Permissão pra criar tags `v*` (dispara build da imagem)

### 3.2 GitHub Container Registry (GHCR)
- `ghcr.io/dexi-digital/synapseos-core:latest` — público OU PAT `read:packages`
- `ghcr.io/dexidigital/synapseos-agentic:latest` — idem
- Configurado uma vez no `~/.docker/config.json` do user `synapseos` na VPS

### 3.3 VPS (SSH)
- Usuário SSH `synapseos` com chave pública dela em `~/.ssh/authorized_keys`
- Membro do grupo `docker` (rodar `docker compose` sem sudo)
- Acesso de leitura/escrita em `/opt/synapseos-core/` e `/opt/synapseos-agentic/`

### 3.4 DNS
- Registro A do domínio principal apontando pra IP da VPS
- (Opcional) subdomínio `gateway.cliente.com.br` se Gateway ativado em domínio próprio

### 3.5 Cloudflare R2 (storage)
- Conta Cloudflare com acesso ao bucket
- API Token com escopo **Object Read & Write** no bucket específico
- Credenciais entregues via cofre de senhas:
  - `STORAGE_ACCESS_KEY_ID`
  - `STORAGE_SECRET_ACCESS_KEY`
  - `STORAGE_ENDPOINT` (formato `https://<account_id>.r2.cloudflarestorage.com`)

### 3.6 n8n (se Agentic ativado)
- URL do n8n self-hosted (ex: `https://n8n.cliente.com.br`)
- API key (`Settings → API → Create API Key`) — permite o Agentic provisionar workflows
- Senha admin do n8n armazenada no cofre

### 3.7 Backups off-site
- Conta Backblaze B2 (ou outro S3-compatible) pra armazenar backups
- Bucket dedicado por cliente (ex: `synapseos-backups-interlivre`)
- API key com escopo escrita no bucket
- Crendenciais armazenadas no cofre

### 3.8 Monitoramento (opcional)
- Acesso read-only nos logs estruturados (Grafana/Loki/Datadog)
- Dashboard de infra (CPU/RAM/disco da VPS)
- Alertas configurados pra: disco > 80%, RAM > 90%, container reiniciando, backup do dia falhou

---

## 4. Setup inicial da VPS (passo-a-passo)

### 4.1 Instalar Docker + Docker Compose v2
```bash
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
newgrp docker
docker compose version  # precisa ser v2+
```

### 4.2 Criar usuário de deploy
```bash
sudo adduser --disabled-password --gecos "" synapseos
sudo usermod -aG docker synapseos
sudo mkdir -p /home/synapseos/.ssh
sudo cp /path/to/lorrayne_id_ed25519.pub /home/synapseos/.ssh/authorized_keys
sudo chown -R synapseos:synapseos /home/synapseos/.ssh
sudo chmod 700 /home/synapseos/.ssh && sudo chmod 600 /home/synapseos/.ssh/authorized_keys
```

### 4.3 Clonar repos
```bash
sudo mkdir -p /opt/synapseos-core /opt/synapseos-agentic
sudo chown synapseos:synapseos /opt/synapseos-core /opt/synapseos-agentic

sudo -u synapseos git clone git@github.com:Dexi-Digital/synapseos-core.git /opt/synapseos-core
sudo -u synapseos git clone git@github.com:dexidigital/synapseos-agentic.git /opt/synapseos-agentic
```

### 4.4 Configurar storage externo (Cloudflare R2)

1. **No painel Cloudflare:**
   - **R2** → Create bucket: `synapseos-<cliente>` (ex: `synapseos-interlivre`)
   - **R2 → Manage API Tokens** → Create token com Object Read+Write no bucket
   - Anotar Access Key ID, Secret, Endpoint

2. **No `.env` do Chatwoot:**
   ```bash
   ACTIVE_STORAGE_SERVICE=s3_compatible
   STORAGE_BUCKET_NAME=synapseos-<cliente>
   STORAGE_REGION=auto
   STORAGE_ENDPOINT=https://<account_id>.r2.cloudflarestorage.com
   STORAGE_ACCESS_KEY_ID=<access_key>
   STORAGE_SECRET_ACCESS_KEY=<secret_key>
   STORAGE_FORCE_PATH_STYLE=true
   ```

3. **Validar após primeiro `up -d`:** enviar uma imagem pelo painel Chatwoot →
   conferir no R2 dashboard que o objeto foi criado.

### 4.5 Configurar Chatwoot core

Detalhes em [`devops_handoff.md` §5.5–§5.7](./devops_handoff.md#5-setup-inicial-da-vps).
Essencial:

```bash
cd /opt/synapseos-core
cp .env.example.prod .env
nano .env  # preencher REPLACE_ME
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d   # web + worker + postgres + redis + release
```

Vars críticas no `.env`:
- `SECRET_KEY_BASE` (`openssl rand -hex 64`)
- `POSTGRES_PASSWORD` (`openssl rand -hex 16`)
- `REDIS_PASSWORD` (`openssl rand -hex 16`)
- `FRONTEND_URL=https://chatwoot.cliente.com.br`
- `VAPID_PUBLIC_KEY` / `VAPID_PRIVATE_KEY` (`docker compose run --rm web bundle exec rake webpush:generate_keys`)
- `STORAGE_*` da etapa 4.4
- `SMTP_*` pra emails de convite

### 4.6 (Opcional) Subir Synapseos Agentic

Detalhes em [`devops_handoff.md` §5.10](./devops_handoff.md#510-opcional-synapseos-agentic).
Resumo:

```bash
cd /opt/synapseos-core
# .env do Chatwoot ganha:
#   SYNAPSEOS_AGENTIC_USER=admin
#   SYNAPSEOS_AGENTIC_PASSWORD=<openssl rand -hex 32>
#   N8N_API_KEY=<criar em /settings/api do n8n>
docker compose -f docker-compose.prod.yml --profile agentic up -d
```

No painel do Chatwoot Super Admin → Installation Configs:
- `SYNAPSEOS_AGENTIC_PANEL_URL=https://chatwoot.cliente.com.br/_agentic/`
- `SYNAPSEOS_AGENTIC_URL=http://agentic:8000` (interno via DNS Docker)
- `SYNAPSEOS_AGENTIC_USER` / `SYNAPSEOS_AGENTIC_PASSWORD`
- `SYNAPSEOS_AGENTIC_ENABLED=true`

### 4.7 (Opcional) Subir Dexi Gateway

Compose isolado em `services/dexi-gateway/`:

```bash
cd /opt/synapseos-core/services/dexi-gateway
cp .env.example .env
nano .env  # preencher SYONET_*, OPENAI_API_KEY (se cliente quer LLM real)
docker compose up -d
```

Configurar webhook no Chatwoot apontando pra `https://gateway.cliente.com.br/webhooks/chatwoot/{tenant_id}` (Ponte B do gateway).

### 4.8 Caddy (reverse proxy + SSL)

Template em `/opt/synapseos-core/docker/Caddyfile.example`:

```bash
sudo apt install -y caddy
sudo cp /opt/synapseos-core/docker/Caddyfile.example /etc/caddy/Caddyfile
sudo sed -i 's/chatwoot\.cliente\.com\.br/chatwoot.<cliente>.com.br/g' /etc/caddy/Caddyfile
sudo systemctl reload caddy
```

Caddy resolve SSL automático via Let's Encrypt no primeiro boot. Caminhos cobertos:
- `/` → Chatwoot web :3000
- `/_agentic/*` → Agentic panel :8000 (loopback only)

Para Gateway com domínio próprio, adicionar bloco separado no `Caddyfile`.

### 4.9 Backups off-site

Script versionado em `/opt/synapseos-core/scripts/backup_offsite.sh`:

```bash
# Instalar rclone
curl https://rclone.org/install.sh | sudo bash

# Configurar remote (interativo, aceitar defaults pra B2/R2/S3)
sudo -u synapseos rclone config

# Cron diário às 03:00
sudo tee /etc/cron.d/synapseos-backup <<'EOF'
0 3 * * * synapseos ALERT_EMAIL=ops@dexidigital.com.br /opt/synapseos-core/scripts/backup_offsite.sh >> /var/log/synapseos-backup.log 2>&1
EOF
```

Backups cobrem:
- `pg_dump` do Postgres do Chatwoot
- (Se Agentic ativo) tar de `/opt/synapseos-agentic/clients/` e `/opt/synapseos-agentic/data/`
- (R2 já é durável — não precisa fazer backup do bucket)

### 4.10 Firewall + segurança básica

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp 80/tcp 443/tcp
sudo ufw enable

sudo apt install -y fail2ban unattended-upgrades
sudo systemctl enable fail2ban

# Desabilitar login SSH por senha
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl reload ssh
```

---

## 5. Pipeline de atualização (Lorrayne ↔ produção)

| Componente | Como atualiza |
|---|---|
| Chatwoot core | `git tag v0.X.Y && git push --tags` → GitHub Actions builda imagem GHCR → `ssh vps && cd /opt/synapseos-core && ./deploy.sh` |
| Agentic | Mesmo padrão no repo `synapseos-agentic` |
| Gateway | Mesmo padrão (compose isolado) |
| Caddy/n8n | Manualmente quando trocar versão major |

Depende dos workflows GitHub Actions já configurados:
- `Dexi-Digital/synapseos-core/.github/workflows/publish_synapseos_docker.yml`
- (A criar) `dexidigital/synapseos-agentic/.github/workflows/publish_docker.yml`

`./deploy.sh` é idempotente: `git pull` + `docker compose pull` + `up -d`. Migrations rodam automáticas via release service.

---

## 6. Backups e disaster recovery

| Dado | Onde fica | Backup | Retenção |
|---|---|---|---|
| Postgres Chatwoot | container | `pg_dump` diário → R2/B2 off-site | 30 dias |
| YAMLs Agentic | `/opt/synapseos-agentic/clients/` + S3 snapshots | tar diário → off-site | 30 dias + snapshots S3 (ilimitado) |
| Anexos WhatsApp | Cloudflare R2 | R2 já é durable (3-region replication) | Ilimitado |
| Logs | container stdout (json-file rotacionado 50m × 5) | não — só observabilidade | 14 dias on-host |

**Restore:** `gunzip -c pg_2026-04-26.sql.gz | docker compose exec -T postgres psql -U postgres chatwoot_production`

Detalhes em `scripts/backup_offsite.sh` e `devops_handoff.md` §7.

---

## 7. Monitoramento

### Healthchecks built-in
- Chatwoot web/worker: já configurados no `docker-compose.prod.yml`
- Agentic: `GET /api/health` → `{"status":"ok"}`
- Gateway: `GET /healthz` → `{"status":"ok"}`
- Caddy: `curl -I https://chatwoot.cliente.com.br` → 200 OK

### Alertas mínimos sugeridos
- Disco > 80%
- RAM > 90% por 5 min
- Container reiniciando em loop (>3× em 10 min)
- Backup diário não executou
- Healthcheck Agentic/Gateway falhando 3× seguidas (se ativados)
- Latência Postgres > 500ms

---

## 8. Acessos por papel

### Lorrayne (produto/dev)
- ✅ SSH na VPS (user `synapseos`)
- ✅ Painel Chatwoot Super Admin (login + senha)
- ✅ Painel Agentic (Basic Auth)
- ✅ R2 Dashboard (read-only é suficiente — só pra debug)
- ✅ Repos GitHub (write)
- ✅ Cofre de senhas Dexi (read pra credenciais do cliente)

### DevOps
- ✅ Root/sudo na VPS
- ✅ Acesso ao registrar de DNS
- ✅ Conta Cloudflare org (admin)
- ✅ Conta Backblaze B2 (admin)
- ✅ Cofre de senhas Dexi (write — armazena credenciais por cliente)

### Cliente (PO)
- ✅ Apenas o painel Chatwoot do domínio dele (login admin)
- ❌ Não tem SSH, não tem Cloudflare, não tem GitHub

---

## 9. Checklist de go-live

Antes de entregar a VPS pro cliente:

**Infra base:**
- [ ] VPS provisionada com specs do §2
- [ ] Docker + Compose v2 instalados, user `synapseos` criado
- [ ] Repos clonados em `/opt/`
- [ ] DNS apontado e propagado (`dig chatwoot.cliente.com.br`)
- [ ] UFW habilitado (22/80/443 only)
- [ ] Fail2ban + unattended-upgrades

**Storage:**
- [ ] Bucket R2 criado, API token gerado
- [ ] `STORAGE_*` no `.env` do Chatwoot
- [ ] Teste de upload (enviar 1 imagem, conferir no R2)

**Chatwoot:**
- [ ] `.env.example.prod` → `.env` preenchido (incluir VAPID, ENABLE_ACCOUNT_SIGNUP=false)
- [ ] `docker compose up -d` rodou sem erro
- [ ] `release` service saiu `Exit 0` (migrations + seeders)
- [ ] Wizard de primeiro login criou conta + 5 stages CRM + 12 labels + 7 AgentBots
- [ ] Caddy SSL válido (`curl -I https://chatwoot.cliente.com.br` → 200)

**WhatsApp:**
- [ ] Inbox criada (Avisa/WABA/Hyperflow conforme contrato)
- [ ] Webhook auto-registrado
- [ ] Teste de texto inbound + outbound OK
- [ ] Teste de mídia (imagem) inbound + outbound OK — confirma R2 funcionando

**Agentic (se ativado):**
- [ ] Profile `agentic` ativo (`docker compose --profile agentic up -d`)
- [ ] `SYNAPSEOS_AGENTIC_PANEL_URL` setado em Installation Configs
- [ ] Item "Synapse Agentic Panel" aparece na sidebar do super_admin
- [ ] Login Basic Auth funciona

**Gateway (se ativado):**
- [ ] Compose isolado rodando em `services/dexi-gateway/`
- [ ] Webhook do Chatwoot configurado pra Ponte B
- [ ] Teste de lead via `curl -X POST .../webhooks/site/...` → contato/conversa criados no Chatwoot

**Backup:**
- [ ] Cron `synapseos-backup` instalado
- [ ] Primeiro backup executou OK (conferir bucket B2/R2)
- [ ] Email/Slack de alerta configurado

**Handoff cliente:**
- [ ] Doc com URL + credenciais primeiro admin entregue
- [ ] Vídeo/walkthrough das funcionalidades principais
- [ ] Canal de suporte definido

---

## 10. Contatos e escalation

| Papel | Quem | Escalation |
|---|---|---|
| Produto / Dev | Lorrayne — devforaiagents@gmail.com | 1ª linha (hora comercial) |
| DevOps | _(a preencher)_ | 1ª linha 24/7 pra incidentes de infra |
| Cliente PO | _(a preencher)_ | Recebe relatórios mensais |

**Repos:**
- `github.com/Dexi-Digital/synapseos-core` (Chatwoot fork)
- `github.com/dexidigital/synapseos-agentic` (panel)

**Imagens GHCR:**
- `ghcr.io/dexi-digital/synapseos-core:latest`
- `ghcr.io/dexidigital/synapseos-agentic:latest`

**Branches de produção:**
- Core: `custom/initial-cleanup` (deploy `main` em alguns ambientes)
- Agentic: `main`

---

## 11. Próximos passos (pra DevOps avaliar)

1. **GitHub Actions do agentic** — criar workflow `publish_docker.yml` análogo ao do core, gerar `ghcr.io/dexidigital/synapseos-agentic:latest` em cada push.
2. **Workflow do core** — atualmente `latest` sai de `custom/initial-cleanup`. Decidir se continua assim ou se promove `main` como default branch.
3. **Tags semver** — adotar `v0.1.0`, `v0.2.0` etc. com release notes pra rollback rápido.
4. **Monitoring stack** — instalar Grafana + Loki + Promtail por cliente (ou usar SaaS como Better Stack).
5. **Multi-arch images** — workflow do core já builda amd64+arm64; replicar no agentic se cliente tiver VPS Graviton/Hetzner CAX.
