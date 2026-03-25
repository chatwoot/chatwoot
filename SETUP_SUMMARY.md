# Resumo da Configuração do Ambiente Local - Chatwoot-FazerAI

**Data**: 25 de março de 2026
**Status**: ✅ Setup Completo

## 📋 Arquivos Criados/Modificados

### 1. Configuração de Ambiente

| Arquivo                                            | Descrição                                      | Uso                                               |
| -------------------------------------------------- | ---------------------------------------------- | ------------------------------------------------- |
| [.env](.env)                                       | Variáveis de ambiente dev com defaults         | Desenvolvimento local nativo                      |
| [.env.local.example](.env.local.example)           | Template para Docker Compose                   | Referência para Docker                            |
| [docker-compose.dev.yaml](docker-compose.dev.yaml) | Docker Compose para PostgreSQL, Redis, MailHog | `docker-compose -f docker-compose.dev.yaml up -d` |

### 2. Scripts de Setup

| Arquivo                      | Descrição                          | Uso                               |
| ---------------------------- | ---------------------------------- | --------------------------------- |
| [setup-dev.sh](setup-dev.sh) | Script automatizado de setup       | `./setup-dev.sh` (one-shot setup) |
| [Makefile](Makefile)         | Make targets para dev (atualizado) | `make help` (list all targets)    |

### 3. Documentação

| Arquivo                                        | Descrição                                    | Público-alvo                   |
| ---------------------------------------------- | -------------------------------------------- | ------------------------------ |
| [QUICKSTART.md](QUICKSTART.md)                 | Setup em ~10 min, commands essenciais        | **Desenvolvedores com pressa** |
| [README_SETUP_LOCAL.md](README_SETUP_LOCAL.md) | Setup completo com troubleshooting detalhado | **Novos desenvolvedores**      |
| [DOCKER_DEV.md](DOCKER_DEV.md)                 | Guia completo Docker Compose                 | **Quem quer usar Docker**      |
| [SETUP_SUMMARY.md](SETUP_SUMMARY.md)           | Este arquivo                                 | Visão geral da configuração    |

---

## 🚀 Como Começar (Escolha 1)

### Opção A: One-Command Setup (Recomendado)

```bash
cd /home/lvkdev/Documentos/GitHub/chatwoot-fazerai
./setup-dev.sh && pnpm dev
```

### Opção B: Docker Compose + Manual

```bash
cd /home/lvkdev/Documentos/GitHub/chatwoot-fazerai
docker-compose -f docker-compose.dev.yaml up -d
bundle install && pnpm install
bundle exec rails db:create db:migrate
pnpm dev
```

### Opção C: Make Commands

```bash
cd /home/lvkdev/Documentos/GitHub/chatwoot-fazerai
make setup-local
make dev
```

---

## 📊 Stack & Versões

```
Ruby:       3.4.4 (via rvm)
Node.js:    24.13.0 (via nvm)
PostgreSQL: 16 (via system ou docker)
Redis:      latest (via system ou docker)
pnpm:       latest
```

---

## 🌐 Serviços & URLs (Pós-Setup)

| Serviço             | URL                   | Porta | Descrição                       |
| ------------------- | --------------------- | ----- | ------------------------------- |
| **Chatwoot App**    | http://localhost:3000 | 3000  | UI principal                    |
| **Vite Dev Server** | http://localhost:3036 | 3036  | Assets com HMR                  |
| **MailHog**         | http://localhost:8025 | 8025  | Email testing UI                |
| **PostgreSQL**      | localhost:5432        | 5432  | Database (via socket/docker)    |
| **Redis**           | localhost:6379        | 6379  | Cache/Queue (via socket/docker) |

---

## 🎯 Make Targets Disponíveis

```bash
make help          # Ver todos os targets

# Setup
make setup-local   # Setup automático completo
make setup         # Install gems & packages

# Database
make db            # Prepare database
make db_create     # Create database
make db_migrate    # Run migrations
make db_seed       # Load test data
make db_reset      # Reset (DESTRUCTIVE!)

# Desenvolvimento
make dev           # Start with pnpm dev (recommended)
make run           # Start with Overmind
make force_run     # Kill stuck processes & restart
make console       # Rails console
make server        # Rails server only

# Testes
make test          # Run all tests
make test-ruby     # RSpec tests
make test-js       # Vitest/Jest tests

# Code Quality
make lint          # Run all linters with auto-fix
make lint-ruby     # RuboCop with auto-fix
make lint-js       # ESLint with auto-fix
```

---

## ✅ Checklist Pós-Setup

Após seguir um dos guias:

- [ ] Ruby 3.4.4 instalado
- [ ] Node.js 24.13.0 instalado
- [ ] Dependências instaladas (`bundle install`, `pnpm install`)
- [ ] PostgreSQL rodando em localhost:5432 (ou docker)
- [ ] Redis rodando em localhost:6379 (ou docker)
- [ ] `.env` configurado com valores corretos
- [ ] `bundle exec rails db:migrate` executado
- [ ] Dev servers iniciando sem erros (`pnpm dev`)
- [ ] http://localhost:3000 acessível
- [ ] Tests passam (`bundle exec rspec`, `pnpm test`)

---

## 📚 Próximos Passos

1. **Ler o Manifesto**: [CLAUDE.md](CLAUDE.md) - Princípios e padrões do projeto
2. **Explorar Estrutura**: `tree app/ lib/ config/` (primeiros níveis)
3. **Criar conta teste**: Acessar localhost:3000 e registrar
4. **Criar feature branch**: `git flow feature start minha-feature`
5. **Ler CONTRIBUTING.md**: Convenções do projeto

---

## 🔧 Troubleshooting Rápido

| Problema                    | Solução                                                                       |
| --------------------------- | ----------------------------------------------------------------------------- |
| Porta 3000 em uso           | `lsof -i :3000 && kill -9 <PID>`                                              |
| Banco não existe            | `bundle exec rails db:create`                                                 |
| Migrações falhando          | `bundle exec rails db:reset`                                                  |
| Conexão recusada Redis      | `redis-cli ping` ou `docker-compose -f docker-compose.dev.yaml up redis`      |
| Conexão recusada PostgreSQL | `psql -U postgres` ou `docker-compose -f docker-compose.dev.yaml up postgres` |
| Dependencies conflicts      | `make burn` (limpa e reinstala)                                               |

---

## 🏠 Estrutura de Diretórios Importante

```
/home/lvkdev/Documentos/GitHub/chatwoot-fazerai/
├── app/                    # Rails app
│   ├── models/
│   ├── controllers/
│   ├── views/
│   └── javascript/         # Vue components
├── config/                 # Rails config
├── db/
│   ├── migrate/            # Migrações
│   └── seeds/
├── lib/                    # Custom code (services, exceptions)
├── spec/                   # RSpec tests
├── .env                    # ← Your config (created)
├── docker-compose.dev.yaml # ← Docker services (created)
├── setup-dev.sh            # ← Automated setup (created)
├── Makefile                # ← Dev commands (updated)
└── docs/
    ├── QUICKSTART.md       # ← 10-minute guide (created)
    ├── README_SETUP_LOCAL.md # ← Complete guide (created)
    ├── DOCKER_DEV.md       # ← Docker guide (created)
    └── CLAUDE.md           # ← Engineering manifesto
```

---

## 💡 Dicas de Desenvolvimento

### I18n (Português)

- Backend strings: `config/locales/en.yml` (depois traduzir para pt_BR)
- Frontend: `app/javascript/locales/en.json`
- Use helpers: `t('.key', scope: 'namespace')`

### Branding (fazer.ai)

- Sempre "fazer.ai" (minúsculo com ponto)
- Nunca "Fazer.ai" ou "FazerAI"

### Vue Components

- Use `<script setup>` (Composition API)
- PascalCase para nomes de componentes
- Tailwind only (sem CSS customizado)

### Testing

- Adicione testes para novos recursos/bugs
- RSpec backend, Vitest/Jest frontend
- `bundle exec rspec spec/path_spec.rb --fail-fast` (development)

### Git Workflow

- Base branch: `develop` (não `main`)
- Feature branches: `git flow feature start nome`
- Commits: Conventional Commits (`feat:`, `fix:`, etc.)

---

## 📞 Suporte

- **Dúvidas de setup**: Veja [README_SETUP_LOCAL.md](README_SETUP_LOCAL.md) (seção Troubleshooting)
- **Padrões de código**: Veja [CLAUDE.md](CLAUDE.md)
- **Como contribuir**: Veja [CONTRIBUTING.md](CONTRIBUTING.md)
- **Copilot instructions**: Veja [.github/copilot-instructions.md](.github/copilot-instructions.md)

---

## 🎉 Ready to Code!

```bash
make dev
# Ou
pnpm dev
```

Acesse: **http://localhost:3000**

Bom desenvolvimento! 🚀

---

**Criado**: 25 de março de 2026
**Stack**: Rails 7.1 + Vue 3 + PostgreSQL 16 + Redis + Sidekiq
