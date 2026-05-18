# Deploy Chatwoot Pro na VPS — Ubuntu + Docker

Guia passo a passo para subir o fork `chatwoot-pro` (com o engine Kanban
embutido) numa VPS Ubuntu 22.04/24.04 ou Debian 12, usando Docker.

Tempo estimado: **20–30 minutos** se você nunca fez isso, **10 minutos** se já.

---

## 0. Pré-requisitos

- VPS com **mínimo 2 vCPU / 4 GB RAM / 30 GB disco** (Chatwoot + Sidekiq + Postgres + Redis confortáveis)
- Domínio apontando para o IP da VPS (registro A no DNS) — necessário para HTTPS automático
- Acesso SSH com `sudo`
- Repositório do fork acessível via HTTPS ou SSH (`github.com/fabriciomuaca1989/chatwoot-pro`)

---

## 1. Preparar o fork local (no seu computador)

Antes de subir para a VPS, precisamos colocar o engine dentro do fork e aplicar
as edições de host.

```sh
# No seu computador
git clone git@github.com:fabriciomuaca1989/chatwoot-pro.git
cd chatwoot-pro

# Copiar o engine Kanban do diretório de trabalho do Cowork
cp -r ~/chatwootPro/engines ./engines
cp -r ~/chatwootPro/deploy ./deploy

# Aplicar as 5 edições de host (script idempotente)
bash deploy/apply-host-edits.sh .

# Confirmar
git status
git diff Gemfile config/routes.rb \
        app/javascript/dashboard/store/index.js \
        app/javascript/dashboard/routes/dashboard/dashboard.routes.js

# Commitar e enviar
git checkout -b feat/kanban-engine
git add engines/ deploy/ \
        Gemfile config/routes.rb \
        app/javascript/dashboard/store/index.js \
        app/javascript/dashboard/routes/dashboard/dashboard.routes.js \
        app/javascript/dashboard/modules/kanban
git commit -m "feat: add Chatwoot Kanban engine"
git push -u origin feat/kanban-engine
```

> No Windows, use Git Bash, WSL ou PowerShell. O script `apply-host-edits.sh`
> depende de `python3` (já presente no Git Bash e em qualquer Ubuntu).

---

## 2. Preparar a VPS

### 2.1 Conectar via SSH

```sh
ssh root@SEU_IP_DA_VPS
# ou: ssh ubuntu@SEU_IP_DA_VPS
```

### 2.2 Instalar Docker (uma vez só)

```sh
# Atualizar pacotes
apt-get update && apt-get upgrade -y

# Instalar Docker via script oficial
curl -fsSL https://get.docker.com | sh

# Habilitar serviço
systemctl enable --now docker

# Validar
docker --version
docker compose version
```

### 2.3 Criar usuário não-root (recomendado)

```sh
adduser chatwoot
usermod -aG docker chatwoot
su - chatwoot
```

### 2.4 Abrir portas no firewall

```sh
# Se usar ufw:
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable
```

---

## 3. Clonar o fork na VPS

```sh
cd ~
git clone https://github.com/fabriciomuaca1989/chatwoot-pro.git
cd chatwoot-pro
git checkout feat/kanban-engine     # ou main, se você fez merge
```

---

## 4. Configurar environment

```sh
# Copiar o template
cp deploy/.env.example .env

# Gerar SECRET_KEY_BASE
docker run --rm ruby:3.4-alpine sh -c "ruby -rsecurerandom -e 'puts SecureRandom.hex(64)'"
# → cole o output em SECRET_KEY_BASE no .env

# Gerar senhas fortes para Postgres e Redis
openssl rand -base64 32   # use no POSTGRES_PASSWORD
openssl rand -base64 32   # use no REDIS_PASSWORD

# Editar o .env com seu editor favorito
nano .env
```

**Variáveis críticas para editar antes de subir:**

```
SECRET_KEY_BASE=<gerado acima>
FRONTEND_URL=https://chatwoot.seu-dominio.com
POSTGRES_PASSWORD=<senha forte>
REDIS_PASSWORD=<senha forte>
REDIS_URL=redis://:<MESMA-SENHA-DO-REDIS>@redis:6379
MAILER_SENDER_EMAIL=Chatwoot <noreply@seu-dominio.com>
```

### 4.1 Configurar o Caddyfile

```sh
# Substituir o domínio placeholder pelo seu real
sed -i 's/chatwoot.seu-dominio.com/chatwoot.exemplo.com/g' deploy/Caddyfile

# Mover Caddyfile e docker-compose para a raiz do projeto
cp deploy/docker-compose.yml ./docker-compose.yml.kanban
cp deploy/Caddyfile          ./Caddyfile
```

Use `docker-compose.yml.kanban` como **substituto** do `docker-compose.production.yaml`
oficial — ele é equivalente mas constrói a imagem a partir do código (com nosso engine).

```sh
# Se quiser substituir o oficial:
mv docker-compose.yml.kanban docker-compose.yaml
# ou rodar com -f explicitamente:  docker compose -f docker-compose.yml.kanban up
```

---

## 5. Build da imagem

```sh
# Primeira build: ~10-20 min (compila gems + assets Vue/JS)
docker compose build

# Verificar que a imagem foi criada
docker images | grep chatwoot-pro
```

> Se faltar memória durante o build do frontend, ajuste `NODE_OPTIONS` no
> Dockerfile aumentando `--max-old-space-size`.

---

## 6. Inicializar banco e rodar migrations

```sh
# Cria o banco, roda TODAS as migrations (Chatwoot + Kanban engine), seeds
docker compose run --rm rails bundle exec rails db:chatwoot_prepare

# Confirmação esperada: você verá as 9 migrations do Kanban rodando:
# == 20260518000001 CreateChatwootKanbanBoards: migrating ===
# == 20260518000002 CreateChatwootKanbanColumns: migrating ===
# ... etc
```

---

## 7. Subir a stack

```sh
docker compose up -d

# Verificar saúde
docker compose ps
docker compose logs -f rails sidekiq | head -50
```

Esperado:
- `rails` healthy em ~30s
- `sidekiq` rodando
- `caddy` fetchando cert do Let's Encrypt (logs mostrarão "certificate obtained successfully")

---

## 8. Criar primeira conta admin

Acesse `https://chatwoot.exemplo.com` no navegador. Como
`ENABLE_ACCOUNT_SIGNUP=false`, você precisa criar a primeira conta via console:

```sh
docker compose exec rails bundle exec rails c
```

No prompt do Rails:

```ruby
user = User.create!(
  name: 'Admin',
  email: 'admin@seu-dominio.com',
  password: 'TrocarSenha@2026',
  display_name: 'Admin'
)
account = Account.create!(name: 'Minha Empresa')
AccountUser.create!(account: account, user: user, role: :administrator)
exit
```

Faça login com esse email/senha.

---

## 9. Habilitar o Kanban no sidebar (rápido)

Por enquanto o item de sidebar não é mexido pelo script (Chatwoot redesenhou o
layout recentemente). Para acessar:

**Diretamente pela URL:** `https://chatwoot.exemplo.com/app/accounts/1/kanban`

(quando quiser, edite `app/javascript/dashboard/components/layout/Sidebar.vue`
seguindo o `INSTALL.md` do engine e rode `docker compose build rails` de novo)

---

## 10. Configurar board auto-create (recomendado para teste)

```sh
docker compose exec rails bundle exec rails c
```

```ruby
account = Account.first
board = ChatwootKanban::Board.create!(
  account_id: account.id,
  name: 'Inbox principal',
  description: 'Cards criados automaticamente de novas conversas',
  settings: {
    'auto_create_from_conversations' => true,
    'done_column_ids' => []   # preencha depois com IDs das colunas "feitas"
  }
)
puts "Board #{board.id} pronto. Colunas geradas: #{board.columns.pluck(:name)}"
exit
```

Agora toda conversa nova vira um card na coluna "Backlog" desse board.

---

## 11. Habilitar real-time (já está ligado, mas valide)

No navegador, abra o Kanban. DevTools → Network → WS:
- Você deve ver uma conexão WebSocket aberta
- Subscribed channel: `ChatwootKanban::BoardChannel`

Faça este teste:
1. Abra `/app/accounts/1/kanban/1` em DUAS abas
2. Arraste um card na aba 1
3. A aba 2 deve atualizar **sem refresh**

---

## 12. Backup contínuo (cuidado básico)

```sh
# Script simples — adicione ao crontab da VPS
cat > /home/chatwoot/backup.sh <<'EOF'
#!/bin/bash
TS=$(date +%Y%m%d-%H%M)
mkdir -p /home/chatwoot/backups
docker compose -f /home/chatwoot/chatwoot-pro/docker-compose.yaml exec -T postgres \
  pg_dump -U postgres chatwoot | gzip > /home/chatwoot/backups/chatwoot-$TS.sql.gz
find /home/chatwoot/backups -mtime +7 -delete
EOF
chmod +x /home/chatwoot/backup.sh

crontab -e
# Adicionar:
# 0 3 * * * /home/chatwoot/backup.sh
```

---

## 13. Atualização posterior (quando upstream Chatwoot lançar nova versão)

```sh
cd ~/chatwoot-pro
git fetch upstream                          # se você adicionou o remote upstream
git checkout feat/kanban-engine
git merge upstream/develop                  # resolver conflitos triviais
git push origin feat/kanban-engine

# Na VPS:
git pull
docker compose build
docker compose run --rm rails bundle exec rails db:migrate
docker compose up -d
```

Esperado: zero conflitos no engine (graças ao namespace isolado), no máximo 2
linhas a refazer no `Gemfile`/`routes.rb` se Chatwoot mexer nesses arquivos
perto das nossas linhas.

---

## Troubleshooting

| Sintoma | Causa provável | Solução |
|---|---|---|
| `rails` reinicia em loop | Falta `SECRET_KEY_BASE` ou `DATABASE_URL` | Conferir `.env` |
| Migrations falham em `chatwoot_kanban_*` | Engine não carregou | Verificar `Gemfile` e rodar `docker compose build` de novo |
| Frontend não mostra menu Kanban | Build pulado | `docker compose build rails && docker compose up -d rails` |
| WebSocket não conecta | Caddy / proxy bloqueando upgrade | Confirmar `Caddyfile` (Caddy faz isso automático) |
| `ActiveRecord::Encryption::Errors::Configuration` | Faltam chaves de criptografia (necessárias só pro GLPI) | Rodar `docker compose run rails bundle exec rails db:encryption:init` e colar no `.env` |
| Erro `WIP limit exceeded` ao mover card | Comportamento esperado | Aumentar `wip_limit` da coluna no admin/console |
| `Rack::Attack` bloqueia em testes | Você atingiu 60 PATCHes/min | Aguardar 1min ou desabilitar via env |

---

## Para o próximo passo

Quando o Kanban estiver rodando e testado:

1. Copie também `engines/chatwoot_glpi_integration/` para o fork
2. Adicione `gem 'chatwoot_glpi_integration', path: 'engines/...'` e o `mount` correspondente
3. `docker compose build && docker compose run --rm rails bundle exec rails db:migrate`
4. Configure a conexão GLPI via `Settings → Integrations → GLPI` (ou rails console)
