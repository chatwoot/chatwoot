# Nexus no Docker (desenvolvimento)

Este guia descreve como subir o **Nexus** localmente com `docker compose`, alinhado ao arquivo `docker-compose.yaml` na raiz do repositório.

## O que sobe por padrão

| Serviço   | Função |
|-----------|--------|
| **rails** | API e app Rails (porta **3000**) |
| **vite**  | Servidor de assets front-end (porta **3036**) |
| **sidekiq** | Filas em background |
| **postgres** | PostgreSQL 16 + pgvector (bancos `chatwoot` e `igaralead`) |
| **redis** | Redis com senha definida no `.env` |
| **mailhog** | SMTP de teste e UI de e-mails |

Serviços **opcionais** no mesmo arquivo (não sobem com `docker compose up` padrão):

- **react-frontend** (porta 3004): build separado em `./frontend`.
- **baileys** (porta 3500): exige o repositório **Baileys** como pasta irmã (`../Baileys`). Ver seção [WhatsApp / Baileys](#whatsapp--baileys).

## Pré-requisitos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (ou Docker Engine + plugin Compose).
- Pelo menos **~8 GB de RAM** livre para o primeiro build.
- Repositório clonado e terminal na **raiz do projeto** (`Nexus/`).

## 1. Variáveis de ambiente (`.env`)

Na raiz do projeto:

```bash
cp .env.example .env
```

Edite o `.env` e garanta valores coerentes com o Compose (desenvolvimento local). Referência mínima:

| Variável | Exemplo (Docker) | Observação |
|----------|-------------------|------------|
| `SECRET_KEY_BASE` | saída de `openssl rand -hex 64` | Obrigatório. |
| `FRONTEND_URL` | `http://localhost:3000` | URL que o browser usa para abrir o app. |
| `FORCE_SSL` | `false` | Evita redirect para HTTPS em dev. |
| `POSTGRES_HOST` | `postgres` | Nome do serviço no Compose. |
| `POSTGRES_PORT` | `5432` | Porta **dentro** da rede Docker. |
| `POSTGRES_DATABASE` | `chatwoot` | Igual ao `POSTGRES_DB` do serviço Postgres. |
| `POSTGRES_USERNAME` | `postgres` | |
| `POSTGRES_PASSWORD` | *(vazio)* | O Postgres do Compose usa `trust` no dev. |
| `REDIS_URL` | `redis://redis:6379/1` | |
| `REDIS_PASSWORD` | ex.: `devredis` | Deve coincidir com o que o Redis usa (`env_file: .env`). |
| `SHARED_DATABASE_NAME` | `igaralead` | Banco “Hub” simulado para login IgaraLead (criado pelo script de init). |
| `ACTIVE_STORAGE_SERVICE` | `local` | Sem MinIO local. |
| `SMTP_ADDRESS` | `mailhog` | E-mail capturado na UI do Mailhog. |
| `SMTP_PORT` | `1025` | |
| `HUB_URL` / `HUB_API_URL` / `HUB_API_KEY` | placeholders | Podem apontar para URLs fictícias se você não tiver Hub local; ajuste quando for integrar. |

O `docker-compose.yaml` já define **`SKIP_ANNOTATE_ON_MIGRATE=true`** nos serviços **rails** e **sidekiq**, para que `db:migrate` no container não carregue o `annotate_rb` (evita falhas conhecidas com Ruby 3.4 / YAML em ambiente montado por volume). Fora do Docker, o comportamento padrão do projeto permanece o mesmo.

## 2. Imagem base (obrigatório na primeira vez)

Os serviços `rails`, `vite` e `sidekiq` dependem da imagem local **`chatwoot:development`**, gerada pelo `Dockerfile` principal:

```bash
docker compose build base
```

Na primeira execução isso pode levar **vários minutos** (Ruby gems + contexto da app).

## 3. Subir os serviços principais

```bash
docker compose up -d postgres redis mailhog vite sidekiq rails
```

### Portas no host

| Porta (host) | Serviço |
|----------------|---------|
| **3000** | Aplicação web (Rails) |
| **3036** | Vite |
| **15434** | Postgres (`localhost:15434` → `5432` no container) |
| **6381** | Redis |
| **8025** | UI do Mailhog (`http://localhost:8025`) |
| **1025** | SMTP do Mailhog (já referenciado no `.env` como `mailhog:1025`) |

A porta **15434** foi escolhida no Compose para reduzir conflito com outros Postgres locais que costumam usar `5434`. Se precisar mudar, edite o mapeamento em `docker-compose.yaml` na seção `postgres.ports`.

## 4. Banco de dados e seed

Na **primeira** subida, após o Postgres estar saudável:

```bash
docker compose exec rails bundle exec rails db:chatwoot_prepare
```

Esse task cria/atualiza o schema do Chatwoot/Nexus e aplica seeds de desenvolvimento quando aplicável.

Se o banco já existir e o seed falhar por dados duplicados (por exemplo, usuário já criado), você pode **recriar volumes** e repetir:

```bash
docker compose down -v
docker compose up -d postgres redis mailhog vite sidekiq rails
# aguarde o Postgres aceitar conexões, depois:
docker compose exec rails bundle exec rails db:chatwoot_prepare
```

### Banco `igaralead` (login compartilhado)

O script `docker/postgres/00-init-igaralead.sh` é montado em `/docker-entrypoint-initdb.d` e roda **apenas na criação do volume** do Postgres. Ele cria o banco `igaralead` e um usuário compatível com `Igaralead::SharedUser`, alinhado ao seed do Nexus (mesmo e-mail e senha do `db/seeds.rb`).

Se você já tinha um volume Postgres **sem** esse init, apague o volume (`docker compose down -v`) ou crie o banco/usuário manualmente conforme o script.

## 5. Conferir se está no ar

```bash
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:3000/app/login
```

Esperado: código **200**.

Logs:

```bash
docker compose logs -f rails
```

## 6. Acessos e logins (desenvolvimento)

Após o `db:chatwoot_prepare` (ou `db:seed` em ambiente já migrado), use as credenciais abaixo.

### Painel do agente / conta (app)

- **URL:** [http://localhost:3000/app/login](http://localhost:3000/app/login)
- **E-mail:** `john@acme.inc`
- **Senha:** `Password1!`

O login IgaraLead valida a senha contra o banco **`igaralead`** (tabela `users`) e sincroniza o utilizador com o utilizador local do Nexus criado pelo seed (`SuperAdmin` na conta de exemplo).

### Super Admin (instalação / administração global)

- **URL:** [http://localhost:3000/super_admin/sign_in](http://localhost:3000/super_admin/sign_in)
- **E-mail:** `john@acme.inc`
- **Senha:** `Password1!`

O utilizador de seed é do tipo `SuperAdmin` (STI na tabela `users`).

### Mailhog (e-mails de teste)

- **URL:** [http://localhost:8025](http://localhost:8025)

## WhatsApp / Baileys

O serviço **baileys** está no profile **`whatsapp`**. Os containers **rails** e **sidekiq** recebem por padrão `BAILEYS_SIDECAR_URL=http://baileys:3500` via `docker-compose.yaml` (pode sobrescrever no `.env`).

### Com código local (build)

Espelhe o repositório Baileys como pasta irmã do Nexus (`../Baileys`), com o `Dockerfile` em `sidecar/Dockerfile`.

```bash
# Subir só o sidecar (Rails já deve estar no ar)
docker compose --profile whatsapp up -d baileys

# Stack comum + Baileys
docker compose --profile whatsapp up -d postgres redis mailhog vite sidekiq rails baileys
```

Reconstruir o sidecar após atualizar o código em `../Baileys`:

```bash
docker compose --profile whatsapp build --no-cache baileys
docker compose --profile whatsapp up -d baileys
```

### Só imagem publicada (sem clone do Baileys)

Em produção usa-se `ghcr.io/${GHCR_OWNER:-igaralead}/baileys-sidecar:latest` (ver `docker-compose.production.yaml`). Para o mesmo em dev, no `docker-compose.yaml` do serviço **baileys** comente temporariamente o bloco `build:` e defina apenas:

```yaml
image: ghcr.io/${GHCR_OWNER:-igaralead}/baileys-sidecar:latest
```

Depois: `docker compose pull baileys && docker compose --profile whatsapp up -d baileys`.

### Variáveis

No `.env`, defina a mesma chave nos dois lados:

- `BAILEYS_SIDECAR_API_KEY` — o Rails valida webhooks com esta chave; o sidecar deve enviar `X-Api-Key` idêntica.

Opcional: `BAILEYS_SIDECAR_URL` se não for usar o hostname `baileys` na rede Compose.

## Comandos úteis

```bash
# Parar tudo (mantém volumes)
docker compose down

# Parar e apagar volumes (apaga Postgres/Redis locais do Compose)
docker compose down -v

# Consola Rails
docker compose exec rails bundle exec rails console

# RSpec / tarefas pontuais
docker compose exec rails bundle exec rspec ...
```

## Resumo rápido (checklist)

1. `cp .env.example .env` e ajustar variáveis (tabela acima).
2. `docker compose build base`
3. `docker compose up -d postgres redis mailhog vite sidekiq rails`
4. `docker compose exec rails bundle exec rails db:chatwoot_prepare`
5. Abrir [http://localhost:3000/app/login](http://localhost:3000/app/login) com `john@acme.inc` / `Password1!`

Em caso de dúvida sobre variáveis gerais do fork, consulte também `.env.example` e `AGENTS.md` na raiz do repositório.
