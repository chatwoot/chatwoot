# 🎉 Bem-vindo ao Chatwoot-FazerAI!

Estrutura de desenvolvimento local já pronta. Escolha seu caminho:

## 🚀 Quick Start (Recomendado)

```bash
# 1. Verificar pré-requisitos
bash preflight-check.sh

# 2. Setup automático (único comando)
./setup-dev.sh

# 3. Iniciar desarrollo
pnpm dev
```

✨ App estará em: **http://localhost:3000**

---

## 📚 Guias de Setup

### Para Iniciantes

👉 **[SETUP_INDEX.md](SETUP_INDEX.md)** - Escolha aqui seu caminho

### Leitura Rápida (10 min)

👉 **[QUICKSTART.md](QUICKSTART.md)** - Commands essenciais

### Setup Completo

👉 **[README_SETUP_LOCAL.md](README_SETUP_LOCAL.md)** - Passo a passo detalhado

### Usando Docker

👉 **[DOCKER_DEV.md](DOCKER_DEV.md)** - Setup com Docker Compose

### Faltam Dependências?

👉 **[INSTALL_DEPENDENCIES.md](INSTALL_DEPENDENCIES.md)** - Instale o que falta

---

## 🔧 Verificação Rápida

```bash
# Rodar checklist de pré-requisitos
bash preflight-check.sh

# Tudo OK? Prossiga com setup
./setup-dev.sh && pnpm dev
```

---

## 📖 Depois de Começar

1. **Leia o Manifesto**: [CLAUDE.md](CLAUDE.md)
   - Princípios e padrões do projeto
   - Decisões técnicas

2. **Contribuindo**: [CONTRIBUTING.md](CONTRIBUTING.md)
   - Git workflow
   - Code review process

3. **Estrutura**:
   - Backend: `app/models`, `app/controllers`, `app/services`
   - Frontend: `app/javascript/components`, `app/views`
   - Database: `db/migrate`

---

## 💻 Make Commands

```bash
make help              # Ver todos os targets
make setup-local       # Setup automático
make dev              # Iniciar desenvolvimento (pnpm dev)
make test             # Rodar todos os testes
make lint             # Linting/formatting
make db_migrate       # Migrations
```

---

## 🌐 URLs Importantes

| Serviço         | URL                   |
| --------------- | --------------------- |
| App             | http://localhost:3000 |
| Assets (Vite)   | http://localhost:3036 |
| Email (MailHog) | http://localhost:8025 |

---

## 🆘 Problemas?

### Pré-requisitos não instalados?

```bash
bash preflight-check.sh
# Vá para: INSTALL_DEPENDENCIES.md
```

### Erro no setup?

Veja: [README_SETUP_LOCAL.md](README_SETUP_LOCAL.md#troubleshooting)

### Quero usar Docker?

Veja: [DOCKER_DEV.md](DOCKER_DEV.md)

---

## ✅ Próximas Ações

1. **Rodar**: `bash preflight-check.sh`
2. **Setup**: `./setup-dev.sh`
3. **Dev**: `pnpm dev`
4. **Ler**: [CLAUDE.md](CLAUDE.md)
5. **Code**: `git flow feature start sua-feature`

---

## 📦 Stack

- **Backend**: Rails 7.1
- **Frontend**: Vue 3 + Vite
- **Database**: PostgreSQL 16 + pgvector
- **Cache/Queue**: Redis + Sidekiq
- **Testing**: RSpec + Vitest
- **Linting**: RuboCop + ESLint
- **Branding**: fazer.ai
- **i18n**: pt_BR + en

---

## 🚀 Comece Agora!

```bash
bash preflight-check.sh && ./setup-dev.sh && pnpm dev
```

Pronto em ~ 10-15 minutos! ⚡

---

**Tempo estimado**: 10-15 min (com pré-requisitos instalados)
**Versão Stack**: Rails 7.1 + Vue 3 + PostgreSQL 16
**Última atualização**: 25 de março de 2026

Dúvidas? Veja [SETUP_INDEX.md](SETUP_INDEX.md)

Happy coding! 🎉
