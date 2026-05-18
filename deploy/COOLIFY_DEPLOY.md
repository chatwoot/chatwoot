# Deploy Chatwoot Pro no Coolify

Coolify (https://coolify.io) é um PaaS auto-hospedado que dispensa Caddy/Nginx
manual — ele provê Traefik com HTTPS automático e puxa direto do seu GitHub.

Pré-requisitos:
- **Coolify já instalado** na sua VPS (https://coolify.io/docs/installation)
- **Seu fork no GitHub** com engines + patches **pushados** (veja `PUSH_TO_GITHUB.md`)
- **Domínio** com registro A apontando para o IP da VPS
- Mínimo 4 GB RAM (build do Chatwoot consome bastante)

Tempo estimado: 5 min de cliques + 15-25 min de build.

---

## 1. Push do seu fork para o GitHub (uma vez só)

Se ainda não fez:

```sh
# No seu PC, dentro do clone do fork
cd ~/chatwoot-pro     # ajuste o caminho

# Copiar o overlay
cp -r ~/chatwootPro/release/chatwoot-pro-overlay/* .
bash deploy/apply-host-edits.sh .

# Commit + push
git checkout -b feat/kanban-engine
git add engines/ deploy/ \
        Gemfile config/routes.rb \
        app/javascript/dashboard/store/index.js \
        app/javascript/dashboard/routes/dashboard/dashboard.routes.js \
        app/javascript/dashboard/modules/kanban
git commit -m "feat: add Chatwoot Kanban engine + deploy scripts"
git push -u origin feat/kanban-engine
```

Confirme em https://github.com/fabriciomuaca1989/chatwoot-pro/tree/feat/kanban-engine
que aparece a pasta `engines/` e o `deploy/`.

---

## 2. Conectar GitHub no Coolify

1. Login no Coolify
2. Menu lateral → **Sources** → **+ Add** → **GitHub App**
3. Siga o fluxo OAuth (Coolify cria um GitHub App pessoal). Autorize ao seu fork.
4. Confirme que `fabriciomuaca1989/chatwoot-pro` aparece em **Source → Repositories**

---

## 3. Criar Postgres + Redis gerenciados (recomendado)

Coolify pode gerenciar databases como serviços separados — mais fácil de fazer
backup e escalar.

### 3.1 Postgres
1. Menu lateral → **Resources** → seu Project → **+ New** → **Database** → **PostgreSQL**
2. Versão: **16**
3. Image: **pgvector/pgvector:pg16** (importante! Chatwoot usa pgvector)
4. Database name: `chatwoot`
5. Username: `postgres`
6. Password: clique **Generate** → **anote** a senha
7. **Start**

### 3.2 Redis
1. **+ New** → **Database** → **Redis**
2. Versão: **7-alpine** ou **alpine**
3. Password: **Generate** → anote
4. **Start**

> Anote os hostnames internos que Coolify mostra (algo como `postgres-abc123` e
> `redis-xyz789`) — você vai usar nas env vars.

---

## 4. Criar o serviço Chatwoot Pro

1. **+ New** → **Resource** → **Application**
2. Source: **GitHub App** → seu fork → branch `feat/kanban-engine`
3. Build Pack: **Docker Compose**
4. **Docker Compose File**: `deploy/docker-compose.coolify.yaml`
5. **Domain**: digite seu domínio (ex `chatwoot.minhaempresa.com`)
   - Coolify configura Traefik + Let's Encrypt automático
6. **Service to expose**: selecione **rails** (porta 3000)

Não dê **Deploy** ainda — primeiro configure as env vars.

---

## 5. Variáveis de ambiente

Vá em **Environment Variables** do serviço criado. Cole as variáveis abaixo,
**ajustando os valores em letra maiúscula**:

```dotenv
SECRET_KEY_BASE=GERE_COM_openssl_rand_hex_64
FRONTEND_URL=https://chatwoot.minhaempresa.com
FORCE_SSL=true
ENABLE_ACCOUNT_SIGNUP=false

# Aponte para os hostnames dos serviços que você criou no Coolify
POSTGRES_HOST=postgres-abc123
POSTGRES_PORT=5432
POSTGRES_DATABASE=chatwoot
POSTGRES_USERNAME=postgres
POSTGRES_PASSWORD=SENHA_DO_POSTGRES_QUE_VOCE_ANOTOU
RAILS_MAX_THREADS=5

REDIS_URL=redis://:SENHA_DO_REDIS@redis-xyz789:6379
REDIS_PASSWORD=SENHA_DO_REDIS

# Gere com:  docker run --rm ruby:3.4-alpine sh -c "ruby -rsecurerandom -e 'puts SecureRandom.hex(32)'"
ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=
ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=
ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=

MAILER_SENDER_EMAIL=Chatwoot <noreply@minhaempresa.com>
SMTP_DOMAIN=minhaempresa.com
SMTP_ADDRESS=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USERNAME=apikey
SMTP_PASSWORD=
SMTP_AUTHENTICATION=plain
SMTP_ENABLE_STARTTLS_AUTO=true

ACTIVE_STORAGE_SERVICE=local
LOG_LEVEL=info
INSTALLATION_NAME=Chatwoot Pro
DEFAULT_LOCALE=pt_BR
```

### Gerar SECRET_KEY_BASE e chaves de criptografia

No terminal local OU em qualquer servidor com Docker:
```sh
# Uma de cada vez — cole no campo correspondente
openssl rand -hex 64        # → SECRET_KEY_BASE
openssl rand -hex 32        # → ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY
openssl rand -hex 32        # → ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY
openssl rand -hex 32        # → ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT
```

### Conectar databases no mesmo network

No Coolify, **se** o Postgres e Redis estão em outro Project ou Network:
- Vá em **Networks** do serviço Chatwoot
- Adicione a network compartilhada com os databases

Se foram criados no **mesmo** project, eles compartilham network por default.

---

## 6. Deploy inicial

1. Clique **Deploy**
2. Coolify mostra logs em tempo real
3. Etapas que você verá nos logs:
   - `cloning repository...`
   - `building docker image...` (10-20 min)
   - `pulling pgvector/pgvector:pg16` (já existe se você criou postgres antes)
   - `creating containers...`
   - `Waiting for postgres to become ready...`
   - `bundle exec rails db:chatwoot_prepare`
   - **9 migrations do Kanban rodando** (`CreateChatwootKanbanBoards`, etc)
   - `Database ready to accept connections`
   - `Puma starting in single mode`
   - **Healthcheck verde** → Coolify libera tráfego

---

## 7. Criar admin via Terminal do Coolify

Coolify tem um botão "Terminal" no serviço que abre shell direto no container.

1. Vá no serviço Chatwoot → **Terminal** (ícone de console)
2. Selecione o container `rails`
3. Cole:

```sh
bundle exec rails runner "
  account = Account.create!(name: 'Minha Empresa')
  user = User.create!(
    name: 'Admin', email: 'admin@minhaempresa.com',
    password: 'SenhaForte123!@#', display_name: 'Admin'
  )
  AccountUser.create!(account: account, user: user, role: :administrator)
  puts 'OK'
"
```

Mude o email e a senha. **Anote a senha.**

---

## 8. Criar board default Kanban (opcional)

No mesmo Terminal:

```sh
bundle exec rails runner "
  account = Account.first
  board = ChatwootKanban::Board.create!(
    account_id: account.id,
    name: 'Inbox principal',
    description: 'Cards criados automaticamente de conversas',
    settings: { 'auto_create_from_conversations' => true }
  )
  puts board.columns.pluck(:name).join(', ')
"
```

---

## 9. Acessar

Abra `https://chatwoot.minhaempresa.com` → login com admin → o Kanban está em
`/app/accounts/1/kanban`.

---

## 10. Configurações do Coolify recomendadas

### Auto-deploy on push
Em **Configuration → Build** do serviço:
- ✅ Auto Deploy: cada push em `feat/kanban-engine` faz Coolify rebuildar e atualizar
- ✅ Watch paths: filtre por `engines/**` ou `app/**` se quiser builds menos sensíveis

### Health checks
- Coolify já lê o healthcheck do compose
- Em **Configuration → Health** confirme: path `/api`, port `3000`

### Backups
- Em cada database (Postgres + Redis), **Configuration → Backup**
- Coolify roda pg_dump no schedule e guarda em S3 / local

### Recursos / limites
- Para começar, deixe Coolify decidir
- Se a VPS tem 4 GB RAM, **defina memory limit do rails em 1.5 GB** (sobra pro Sidekiq + Postgres + Redis)

---

## Troubleshooting

| Sintoma | Causa | Solução |
|---|---|---|
| Build falha em "out of memory" | Compilação do frontend é pesada | Aumente swap da VPS: `fallocate -l 4G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile` |
| `password authentication failed for user "postgres"` | env var diferente do real | Coolify mostra senha no card do Postgres — re-cole exatamente igual |
| `redis: NOAUTH` | REDIS_URL não inclui senha | Confira: `redis://:SENHA@hostname:6379` (note os dois-pontos antes da senha) |
| Migrations não rodam | Coolify não chama `db:chatwoot_prepare` automaticamente | Adicione **Pre-deploy Command**: `bundle exec rails db:chatwoot_prepare` |
| HTTPS dá erro de cert | DNS ainda não propagou | Aguarde 5-30 min, refaça deploy |
| Kanban responde 404 em `/api/v1/.../kanban/boards` | Engine não montou | Cheque logs: `bundle exec rails routes -g kanban` deve listar rotas |
| WebSocket falha | Traefik não está fazendo upgrade | Em **Settings → Network → Advanced**, marque "Enable WebSocket" |

### Pre-deploy Command (importante!)

Em **Configuration → Build → Pre-deploy Command**:
```sh
bundle exec rails db:chatwoot_prepare
```

Isso garante que toda vez que você fizer um push (e Coolify redeploy), as
migrations novas rodam **antes** de subir o novo container.

---

## Atualizações futuras

Quando você adicionar o engine GLPI ou puxar upstream do Chatwoot:

```sh
# Local
git fetch upstream
git merge upstream/develop
git push origin feat/kanban-engine
```

Coolify detecta o push e redeploya automaticamente (com migrations via Pre-deploy).

---

## Próximo módulo — GLPI

Quando o Kanban estiver estável:

1. No seu fork local, descomente/adicione o gem do GLPI no Gemfile:
   ```ruby
   gem 'chatwoot_glpi_integration', path: 'engines/chatwoot_glpi_integration'
   ```
2. Adicione o mount em `config/routes.rb`:
   ```ruby
   mount ChatwootGlpiIntegration::Engine => '/'
   ```
3. Push → Coolify redeploya → migrations rodam → pronto

Depois configure a conexão GLPI no UI: **Settings → Integrations → GLPI**.
