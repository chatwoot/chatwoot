# Synapse OS — Handoff DevOps

Documento de entrega para o time de infraestrutura. Descreve como subir
o Synapse OS numa VPS dedicada, qual pipeline conecta o repo Git à
imagem Docker, e quais acessos o time de produto (Lorrayne) precisa
manter pra rodar atualizações sem depender do DevOps a cada push.

**Modelo de entrega:** 1 VPS dedicada por cliente (ex: Interlivre).
Sem multi-tenancy. Sem orquestrador. Stack completa (web + worker +
Postgres + Redis + storage) em uma única máquina via Docker Compose.

---

## 1. Visão geral da arquitetura

```
  ┌──────────────────────────────────────────────────────────────┐
  │  VPS do cliente (Ubuntu 22.04+ / Debian 12)                  │
  │                                                              │
  │   ┌──────────┐        ┌──────────────────────────────────┐   │
  │   │  Caddy   │ :443   │          Docker Compose          │   │
  │   │ (SSL LE) │ ─────► │                                  │   │
  │   └──────────┘        │   ┌────────┐      ┌──────────┐   │   │
  │                       │   │  web   │      │  worker  │   │   │
  │                       │   │ Puma   │      │ Sidekiq  │   │   │
  │                       │   │ :3000  │      │          │   │   │
  │                       │   └────┬───┘      └────┬─────┘   │   │
  │                       │        │               │         │   │
  │                       │        └──── volume ───┘         │   │
  │                       │             `storage`            │   │
  │                       │                                  │   │
  │                       │   ┌──────────┐   ┌────────────┐  │   │
  │                       │   │ postgres │   │   redis    │  │   │
  │                       │   │ pgvector │   │ 7-alpine   │  │   │
  │                       │   └──────────┘   └────────────┘  │   │
  │                       └──────────────────────────────────┘   │
  └──────────────────────────────────────────────────────────────┘
           ▲
           │ docker pull ghcr.io/dexi-digital/synapseos-core:<tag>
           │
  ┌────────┴─────────────────────────┐
  │  GitHub Container Registry       │
  │  ghcr.io/dexi-digital/synapseos-core  │
  └──────────────────────────────────┘
           ▲
           │ GitHub Actions build+push em `git push tag v*`
           │
  ┌────────┴─────────────────────────┐
  │  Repo: Dexi-Digital/synapseos    │
  │  Branch: custom/initial-cleanup  │
  └──────────────────────────────────┘
```

**Pontos-chave:**

1. **`web` e `worker` compartilham o volume `storage`.** Esse é o detalhe
   que permite usar ActiveStorage local (sem S3/R2). Anexo enviado pelo
   `web` fica disponível pro `worker` processar/enviar pra API externa.
2. **Postgres usa `pgvector/pg14`**, não o Postgres oficial. Precisamos
   da extensão pgvector pro módulo Captain (embeddings).
3. **Redis tem senha obrigatória** (`REDIS_PASSWORD`). Usado pra Sidekiq,
   ActionCable e cache.
4. **Caddy (ou nginx) na frente** faz SSL via Let's Encrypt. Sem isso
   o WhatsApp webhook da Avisa API não funciona (precisa de HTTPS).

---

## 2. Requisitos de máquina

| Recurso | Mínimo | Recomendado |
|---|---|---|
| CPU | 4 vCPU | 8 vCPU |
| RAM | 8 GB | 16 GB |
| Disco | 50 GB SSD | 100 GB NVMe |
| SO | Ubuntu 22.04 | Ubuntu 24.04 LTS |
| Portas abertas | 80, 443 | 80, 443, 22 (SSH) |

Dimensionamento pensado em **até 100 agentes simultâneos** com
throughput normal de WhatsApp. Se o cliente passar de 150 agentes ou
tiver picos agressivos, considerar:
- Subir pra 16 vCPU / 32 GB
- Ou separar Postgres em VPS própria (trocar `POSTGRES_HOST` no `.env`)

---

## 3. Acessos necessários (Lorrayne / time de produto)

Pra que eu consiga **atualizar a aplicação sem depender do DevOps**,
preciso dos seguintes acessos provisionados:

### 3.1 Repo GitHub
- **Write access** no repo `Dexi-Digital/synapseos` (já tenho)
- Permissão pra criar **tags** (`v0.2.0`, `v0.3.0`, etc) — é o que
  dispara o build da imagem
- Permissão pra disparar **GitHub Actions workflows** manualmente
  (`workflow_dispatch`)

### 3.2 GitHub Container Registry (GHCR)
- **Packages: write** no escopo `Dexi-Digital` pra publicar imagens
- **Packages: read** pra imagem ser puxada pela VPS (configurar como
  público OU provisionar PAT pra `docker login ghcr.io` na VPS)

### 3.3 VPS (SSH)
- Usuário SSH com chave pública minha (`id_ed25519.pub`) em
  `~/.ssh/authorized_keys`
- Membro do grupo `docker` (pra rodar `docker compose` sem sudo)
- Acesso de leitura/escrita no diretório do projeto (ex:
  `/opt/synapseos-core`)

### 3.4 DNS / Caddy
- DNS do domínio do cliente apontado pra IP da VPS (registro A)
- Acesso de edição no `/etc/caddy/Caddyfile` (via sudo ou grupo dedicado)
  pra eventual troca de domínio

### 3.5 Monitoramento (opcional, se houver)
- Acesso read-only nos logs estruturados (ex: Grafana/Loki/Datadog)
- Acesso ao dashboard de infra (CPU/RAM/disco da VPS)

---

## 4. Pipeline de atualização (Git → VPS)

Fluxo do que acontece quando eu rodo `git push` + `git tag`:

```
  1. Commit no branch custom/initial-cleanup
  2. git tag v0.2.1 && git push origin v0.2.1
  3. GitHub Actions dispara "build-and-push-image.yml"
     ├── docker build -f docker/Dockerfile
     ├── docker tag ghcr.io/dexi-digital/synapseos-core:v0.2.1
     ├── docker tag ghcr.io/dexi-digital/synapseos-core:latest
     └── docker push (ambas as tags)
  4. SSH na VPS:
     cd /opt/synapseos-core
     git pull  (opcional, só se mudou docker-compose.prod.yml)
     docker compose -f docker-compose.prod.yml pull
     docker compose -f docker-compose.prod.yml up -d
  5. Serviço `release` do compose roda db:chatwoot_prepare
     (migrations + seeders) antes de web/worker subirem — automático
     em cold start e em cada `up -d`
  6. Healthcheck do Caddy confirma que web voltou
```

**Tempo médio do pipeline completo:** 8–12 min (build da imagem) + 2 min
(pull+restart na VPS). Zero downtime em restarts normais; durante
migration pesada pode ter 30s–2min de indisponibilidade.

### 4.1 Workflow GitHub Actions

Já versionado em `.github/workflows/publish_synapseos_docker.yml`.
Dispara em:
- Push na branch `custom/initial-cleanup` (gera tags `custom-initial-cleanup`, `sha-<curto>` e `latest`).
- Push em tags `v*` (gera tag da versão + `sha-<curto>`).
- `workflow_dispatch` com input `tag` opcional.

Imagem publicada em `ghcr.io/<owner>/synapseos-core`. O cache Buildx é
reutilizado entre builds (`type=gha`), então tag subsequente leva ~3–5 min.

### 4.2 Script de deploy na VPS

Já versionado em `/opt/synapseos-core/deploy.sh` (vem no `git clone`).
Rodar após qualquer tag nova:

```bash
cd /opt/synapseos-core
./deploy.sh

# opcional — deploy de tag específica:
SYNAPSEOS_TAG=v0.3.0 ./deploy.sh
```

O script faz `git pull`, `docker compose pull`, `up -d` (que dispara o
`release` e as migrations) e `docker image prune`. Idempotente.

---

## 5. Setup inicial da VPS (passo-a-passo pro DevOps)

Esses passos são executados **uma única vez** na provisão da VPS. Lorrayne
só precisa entrar em cena após o item 7.

### 5.1 Instalar Docker + Docker Compose

```bash
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
newgrp docker

docker --version
docker compose version  # precisa ser v2+
```

### 5.2 Criar usuário de deploy

```bash
sudo adduser --disabled-password --gecos "" synapseos
sudo usermod -aG docker synapseos
sudo mkdir -p /home/synapseos/.ssh
sudo cp /path/to/lorrayne_id_ed25519.pub /home/synapseos/.ssh/authorized_keys
sudo chown -R synapseos:synapseos /home/synapseos/.ssh
sudo chmod 700 /home/synapseos/.ssh
sudo chmod 600 /home/synapseos/.ssh/authorized_keys
```

### 5.3 Clonar o repo

```bash
sudo mkdir -p /opt/synapseos-core
sudo chown synapseos:synapseos /opt/synapseos-core
sudo -u synapseos git clone \
  git@github.com:Dexi-Digital/synapseos.git /opt/synapseos-core
cd /opt/synapseos-core
git checkout custom/initial-cleanup
```

### 5.4 GHCR: público vs privado

Por padrão, pacotes novos no GHCR nascem **privados**. Duas opções:

**A) Tornar o pacote público (mais simples, recomendado enquanto não houver
código sensível só na imagem):**
1. Acessar https://github.com/orgs/Dexi-Digital/packages → `synapseos-core`
2. Package settings → Change visibility → Public
3. Nenhuma config adicional na VPS, `docker pull` funciona direto.

**B) Manter privado e autenticar na VPS com PAT:**

Criar PAT em https://github.com/settings/tokens (escopo `read:packages`,
SSO autorizado no org se aplicável). Armazenar no cofre do DevOps e:

```bash
sudo -u synapseos bash -c '
echo "$GHCR_PAT" | docker login ghcr.io -u synapseos-bot --password-stdin
'
```

A credencial fica em `~synapseos/.docker/config.json`. Em cada VPS nova,
repetir esse login antes do primeiro `docker compose pull`.

### 5.5 Configurar `.env`

```bash
sudo -u synapseos cp .env.example.prod .env
sudo -u synapseos nano .env
```

Preencher todos os `REPLACE_ME`:

| Variável | Como gerar |
|---|---|
| `SECRET_KEY_BASE` | `openssl rand -hex 64` |
| `POSTGRES_PASSWORD` | `openssl rand -hex 16` |
| `REDIS_PASSWORD` | `openssl rand -hex 16` |
| `REDIS_URL` | `redis://:<REDIS_PASSWORD>@redis:6379` |
| `VAPID_PUBLIC_KEY` / `VAPID_PRIVATE_KEY` | `docker compose -f docker-compose.prod.yml run --rm web bundle exec rake webpush:generate_keys` (rodar 1×, antes do primeiro `up -d`) |
| `FRONTEND_URL` | `https://chatwoot.cliente.com.br` |
| `SMTP_*` | Credenciais do SES/Mailgun/SendGrid |
| `MAILER_SENDER_EMAIL` | `noreply@cliente.com.br` |

### 5.6 Subir a stack

```bash
sudo -u synapseos docker compose -f docker-compose.prod.yml pull
sudo -u synapseos docker compose -f docker-compose.prod.yml up -d
```

`docker compose up -d` já dispara o serviço `release`, que roda
`db:chatwoot_prepare` (migrations + seeders) e só permite que `web`
e `worker` subam depois que esse passo termina com sucesso. Nada
manual pra rodar na primeira subida.

### 5.7 Proxy reverso + SSL (Caddy)

Template versionado em `docker/Caddyfile.example`:

```bash
sudo apt install -y caddy
sudo cp /opt/synapseos-core/docker/Caddyfile.example /etc/caddy/Caddyfile
sudo sed -i 's/chatwoot\.cliente\.com\.br/chatwoot.<cliente>.com.br/g' \
  /etc/caddy/Caddyfile
sudo systemctl reload caddy
```

Validar SSL com `curl -I https://chatwoot.<cliente>.com.br` — deve
retornar 200 OK.

### 5.8 Handoff pra Lorrayne

Após os passos acima, a aplicação está acessível. Lorrayne entra no
domínio, cria a primeira conta via wizard (que dispara
`AccountDefaults.seed` automaticamente: 5 stages do CRM, 12 labels do
contrato, 7 AgentBots do esquadrão, custom attributes), e a partir
daí ela pode operar sem DevOps.

---

## 6. Rotina de atualização (quem faz o quê)

| Ação | Quem executa | Frequência esperada |
|---|---|---|
| Commit + push no branch | Lorrayne | Várias vezes por semana |
| Criar tag `v*` | Lorrayne | 1–2× por semana |
| Build+push da imagem no GHCR | GitHub Actions (automático) | Por tag |
| SSH na VPS + `./deploy.sh` | Lorrayne | Por tag |
| Rollback pra tag anterior | Lorrayne ou DevOps | Emergência |
| Upgrade de SO / Docker | DevOps | Trimestral |
| Rotacionar `SECRET_KEY_BASE` | DevOps + Lorrayne | Anual ou incidente |
| Restore de backup | DevOps | Emergência |

### 6.1 Rollback (caso deploy quebre)

```bash
cd /opt/synapseos-core

# descobrir a tag anterior
docker image ls ghcr.io/dexi-digital/synapseos-core

# editar .env: SYNAPSEOS_TAG=v0.2.0  (versão estável anterior)
sed -i 's/SYNAPSEOS_TAG=.*/SYNAPSEOS_TAG=v0.2.0/' .env

docker compose -f docker-compose.prod.yml up -d
```

Se a quebra foi por migration incompatível, rollback da imagem **não**
reverte a migration. Nesse caso acionar DevOps pra `rails db:rollback`
manual.

---

## 7. Backup e disaster recovery

Dois volumes contêm dados críticos: **`postgres_data`** (banco) e
**`storage`** (anexos do WhatsApp). Redis é ephemeral (só filas).

### 7.1 Backup automático diário (off-site)

Script versionado em `scripts/backup_offsite.sh`. Faz dump do Postgres +
tar do ActiveStorage e envia para bucket externo via `rclone` (B2, R2, S3).
Alerta por email e/ou Slack em caso de falha. Rotaciona backups antigos
automaticamente.

Setup:

```bash
# 1. Instalar rclone
curl https://rclone.org/install.sh | sudo bash

# 2. Configurar remote
rclone config  # criar remote chamado "offsite"

# 3. Agendar no cron (diário às 03:00)
echo '0 3 * * * root ALERT_EMAIL=ops@dexidigital.com.br /opt/synapseos-core/scripts/backup_offsite.sh >> /var/log/synapseos-backup.log 2>&1' \
  | sudo tee /etc/cron.d/synapseos-backup
```

Variáveis de ambiente: `RCLONE_REMOTE`, `RCLONE_BUCKET`,
`BACKUP_RETENTION`, `ALERT_EMAIL`, `ALERT_SLACK_WEBHOOK`.
Ver `scripts/backup_offsite.sh` para defaults e detalhes.

### 7.2 Restore

```bash
# Postgres
gunzip -c pg_2026-04-24.sql.gz | \
  docker compose exec -T postgres psql -U postgres chatwoot_production

# Storage
docker run --rm \
  -v synapseos-core_storage:/data \
  -v $PWD:/backup \
  alpine tar xzf /backup/storage_2026-04-24.tar.gz -C /data
```

---

## 8. Monitoramento mínimo

### 8.1 Healthchecks built-in

Os 4 serviços têm healthcheck:
- `postgres`: `pg_isready`
- `redis`: `redis-cli ping`
- `web`: `curl -fsS http://localhost:3000/api`
- `worker`: `pgrep sidekiq`

Conferir estado via `docker compose -f docker-compose.prod.yml ps` —
coluna `STATUS` mostra `healthy` / `unhealthy` / `starting`.

### 8.2 Logs

```bash
# todos os serviços
docker compose -f docker-compose.prod.yml logs -f --tail=100

# só web
docker compose -f docker-compose.prod.yml logs -f web

# só worker
docker compose -f docker-compose.prod.yml logs -f worker
```

A rotação de logs já está configurada **por serviço** no compose
(`json-file`, 50 MB × 5 arquivos = ~250 MB por container no pior caso).
Não precisa mexer em `/etc/docker/daemon.json`.

### 8.3 Métricas de sistema

Instalar `node_exporter` + Prometheus + Grafana se o cliente exigir
dashboard de infra. Não é bloqueante pro go-live.

### 8.4 Alertas sugeridos

- Disco > 80% ocupado (storage cresce com anexos)
- RAM > 90% por mais de 5 min
- Container `web` ou `worker` reiniciando em loop
- Latência Postgres > 500ms
- Backup diário não executou

---

## 9. Segurança

### 9.1 Firewall (UFW)

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP (Caddy → redirect 443)
sudo ufw allow 443/tcp   # HTTPS
sudo ufw enable
```

Postgres (5432) e Redis (6379) ficam **apenas** na rede interna do
Docker — não expor ao host.

### 9.2 Fail2ban (SSH)

```bash
sudo apt install -y fail2ban
sudo systemctl enable fail2ban
```

### 9.3 Atualizações automáticas

```bash
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

### 9.4 Secrets

- **Nunca** commitar `.env` (já no `.gitignore`)
- `SECRET_KEY_BASE` rotacionar invalidará todas as sessões
- PAT do GHCR com escopo **só leitura** (`read:packages`)
- SSH: desabilitar login por senha, só chave pública

```bash
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' \
  /etc/ssh/sshd_config
sudo systemctl reload ssh
```

---

## 10. Troubleshooting de primeira linha

| Sintoma | Diagnóstico | Fix |
|---|---|---|
| 502 Bad Gateway | `web` não subiu | `docker compose logs web` |
| WhatsApp webhook 401 | `FRONTEND_URL` errada | Editar `.env` + restart |
| Mídia outbound falha | Volume `storage` não montado no worker | Conferir `docker-compose.prod.yml` |
| Sidekiq não processa | Worker caiu | `docker compose restart worker` |
| Login loop | `SECRET_KEY_BASE` mudou | Restaurar valor anterior OU limpar cookies |
| Disco cheio | Anexos antigos | `docker system prune -a` + revisar retenção backup |
| Postgres lento | Sem VACUUM | `docker compose exec postgres vacuumdb -z -U postgres chatwoot_production` |
| Certificado SSL expirado | Caddy sem rede pra LE | `sudo systemctl restart caddy` |

---

## 11. Checklist de go-live

Antes de entregar a VPS pra cliente:

- [ ] VPS provisionada com specs mínimas (item 2)
- [ ] Docker + Docker Compose v2 instalados
- [ ] Usuário `synapseos` criado com chave SSH de Lorrayne
- [ ] Repo clonado em `/opt/synapseos-core`
- [ ] `.env` preenchido com todos os secrets gerados via `openssl`
- [ ] GHCR login configurado (se imagem privada)
- [ ] `docker compose up -d` executado com sucesso
- [ ] `db:chatwoot_prepare` rodou sem erro
- [ ] Caddy configurado com domínio do cliente + SSL válido
- [ ] DNS apontado e propagado (`dig chatwoot.cliente.com.br`)
- [ ] UFW habilitado (apenas 22/80/443)
- [ ] Cron de backup diário instalado
- [ ] Off-site backup configurado (rclone / s3 sync)
- [ ] Primeiro login feito — wizard criou conta + seeders rodaram
- [ ] Inbox Avisa criada + webhook registrado
- [ ] Teste de envio/recebimento WhatsApp OK (texto + mídia)
- [ ] Acesso SSH de Lorrayne validado (`./deploy.sh` dry-run)
- [ ] Credenciais de recovery armazenadas no cofre do DevOps
- [ ] Doc de handoff entregue pro cliente (URL + primeiro admin)

---

## 12. Contatos

| Papel | Nome | Contato |
|---|---|---|
| Produto / Dev | Lorrayne | devforaiagents@gmail.com |
| DevOps | _(a preencher)_ | |
| Cliente (PO) | _(a preencher)_ | |

**Repo:** `github.com/Dexi-Digital/synapseos`
**Imagem:** `ghcr.io/dexi-digital/synapseos-core`
**Branch de produção:** `custom/initial-cleanup`
