# 📚 Guias de Setup - Chatwoot-FazerAI

Bem-vindo! Escolha o guia que melhor se aplica à sua situação:

## 🚀 Quero Começar Rápido (5-10 minutos)

**→ Leia**: [QUICKSTART.md](QUICKSTART.md)

Neste guia você encontra:

- ✓ Pré-requisitos checklist
- ✓ Um comando (opcional: script de setup)
- ✓ URL para acessar a app
- ✓ Comandos essenciais

**Ideal para**: Quem já tem Ruby, Node, PostgreSQL, Redis instalados.

---

## 📋 Preciso de Setup Completo e Detalhado

**→ Leia**: [README_SETUP_LOCAL.md](README_SETUP_LOCAL.md)

Neste guia você encontra:

- ✓ Instruções passo-a-passo
- ✓ Instalação de cada dependência (por SO)
- ✓ Setup manual ou automatizado
- ✓ Seção de troubleshooting completa
- ✓ Testes e validação

**Ideal para**: Novo no projeto, quer entender cada passo.

---

## 🐳 Prefiro Usar Docker

**→ Leia**: [DOCKER_DEV.md](DOCKER_DEV.md)

Neste guia você encontra:

- ✓ Setup com Docker Compose
- ✓ Um arquivo `docker-compose.dev.yaml`
- ✓ Comandos Docker úteis
- ✓ Como resetar environments
- ✓ Troubleshooting Docker

**Ideal para**: Quem tem Docker e quer isolamento de serviços.

---

## 🔴 Faltam Dependências do Sistema

**→ Leia**: [INSTALL_DEPENDENCIES.md](INSTALL_DEPENDENCIES.md)

Neste guia você encontra:

- ✓ Status das dependências da sua máquina
- ✓ Instalação por sistema operacional (Ubuntu, macOS)
- ✓ Verificação de cada ferramenta
- ✓ Troubleshooting de instalação

**Ideal para**: Você tem Ruby/Node, mas falta Redis/PostgreSQL/Docker.

---

## 📊 Resumo de Tudo

**→ Leia**: [SETUP_SUMMARY.md](SETUP_SUMMARY.md)

Neste guia você encontra:

- ✓ Arquivos criados/modificados
- ✓ Lista de make targets
- ✓ URLs e portas dos serviços
- ✓ Estrutura de diretórios
- ✓ Dicas de desenvolvimento

**Ideal para**: Visão geral rápida, referência.

---

## 🏗️ Quero Entender a Arquitetura

**→ Leia**: [CLAUDE.md](CLAUDE.md)

Neste arquivo você encontra:

- ✓ Missão e princípios inegociáveis
- ✓ Stack oficial do projeto
- ✓ Regras de engenharia
- ✓ Diretrizes de código
- ✓ Critérios de qualidade e testes
- ✓ Segurança e observabilidade

**Ideal para**: Compreender a filosofia e padrões do projeto.

---

## 🚀 Árvore de Decisão Rápida

```
Bem-vindo ao Chatwoot-FazerAI!

Tenho todos os pré-requisitos instalados?
├─ SIM → [QUICKSTART.md] (~10 min)
└─ NÃO → [INSTALL_DEPENDENCIES.md] (identifica o que falta)
         └─ Depois → [QUICKSTART.md]

Prefiro Docker?
├─ SIM → [DOCKER_DEV.md]
└─ NÃO → [README_SETUP_LOCAL.md]

Quero troubleshooting?
└─ [README_SETUP_LOCAL.md] (seção Troubleshooting)

Quero entender o projeto?
└─ [CLAUDE.md] (Manifesto de Engenharia)
```

---

## 📁 Estrutura de Arquivos Criados

```
chatwoot-fazerai/
├── .env                          # Variáveis de ambiente (local)
├── .env.local.example            # Template para Docker Compose
├── docker-compose.dev.yaml       # Docker Compose para dev
├── setup-dev.sh                  # Script automático de setup
├── Makefile                      # (atualizado com targets)
│
├── QUICKSTART.md                 # ← Comece aqui (5 min)
├── README_SETUP_LOCAL.md         # ← Setup completo
├── DOCKER_DEV.md                 # ← Setup com Docker
├── INSTALL_DEPENDENCIES.md       # ← Faltam dependências?
├── SETUP_SUMMARY.md              # ← Visão geral
├── SETUP_INDEX.md                # ← Este arquivo
│
├── CLAUDE.md                     # ← Manifesto (read after setup)
├── README.md                     # Official Chatwoot README
└── CONTRIBUTING.md               # Contribuindo
```

---

## ✅ Checklist Pós-Setup

100% pronto quando:

- [ ] `ruby -v` mostra 3.4.4
- [ ] `node -v` mostra v24.13.0
- [ ] `redis-cli ping` retorna PONG
- [ ] `psql -U postgres -c "SELECT 1"` funciona
- [ ] `pnpm dev` inicia sem erros
- [ ] http://localhost:3000 acessível
- [ ] `bundle exec rspec` passa
- [ ] `pnpm test` passa

---

## 💬 Próximas Ações

1. **Escolha um guia acima** baseado na sua situação
2. **Siga os passos** até ter a app rodando em localhost:3000
3. **Leia [CLAUDE.md](CLAUDE.md)** para aprender padrões
4. **Crie uma feature branch**: `git flow feature start minha-feature`
5. **Desenvolva com confiança!**

---

## 🎯 TL;DR - The Fastest Path

**Se você tem tudo instalado:**

```bash
./setup-dev.sh && pnpm dev
# Acesse: http://localhost:3000
```

**Se usa Docker:**

```bash
docker-compose -f docker-compose.dev.yaml up -d
bundle install && pnpm install
make db_create && make db_migrate
pnpm dev
# Acesse: http://localhost:3000
```

**Com Make:**

```bash
make setup-local && make dev
```

---

## 📞 Precisa de Ajuda?

1. **Setup**: [README_SETUP_LOCAL.md](README_SETUP_LOCAL.md) → Troubleshooting
2. **Dependências**: [INSTALL_DEPENDENCIES.md](INSTALL_DEPENDENCIES.md)
3. **Padrões**: [CLAUDE.md](CLAUDE.md)
4. **Contribuição**: [CONTRIBUTING.md](CONTRIBUTING.md)

---

**Versão**: 1.0
**Data**: 25 de março de 2026
**Status**: ✅ Completo

Bom desenvolvimento! 🚀
