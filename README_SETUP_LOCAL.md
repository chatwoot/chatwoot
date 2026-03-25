# Setup Local Chatwoot-FazerAI Development Environment

Este guia oferece instruções passo a passo para configurar o ambiente de desenvolvimento local do chatwoot-fazerai em seu computador.

## 📋 Pré-requisitos

### Versões Obrigatórias

- **Ruby**: 3.4.4 (gerenciar com `rvm`)
- **Node.js**: 24.13.0 (gerenciar com `nvm`)
- **PostgreSQL**: 16.x
- **Redis**: latest (Alpine)
- **pnpm**: latest

### Verificar Instalações

```bash
ruby -v          # Deve mostrar ruby 3.4.4
node -v          # Deve mostrar v24.13.0
psql --version   # Deve mostrar PostgreSQL 16.x
redis-cli --version
pnpm -v
```

## 🚀 Setup Inicial (Automatizado)

### Opção 1: Usar Script de Setup (Recomendado)

```bash
# Torne o script executável
chmod +x setup-dev.sh

# Execute o script
./setup-dev.sh
```

O script automaticamente:

- ✓ Verifica pré-requisitos
- ✓ Instala dependências Ruby (gems via bundler)
- ✓ Instala dependências Node.js (via pnpm)
- ✓ Cria e migra o banco de dados
- ✓ Configura chaves de criptografia
- ✓ Fornece próximos passos

### Opção 2: Setup Manual (Passo a Passo)

#### 1. Instalar Ruby 3.4.4

Com `rvm`:

```bash
rvm install 3.4.4
rvm use 3.4.4
ruby -v  # Verificar
```

#### 2. Instalar Node.js 24.13.0

Com `nvm`:

```bash
nvm install 24.13.0
nvm use 24.13.0
node -v  # Verificar
```

#### 3. Instalar pnpm

```bash
npm install -g pnpm
pnpm -v  # Verificar
```

#### 4. Instalar PostgreSQL 16

**No Ubuntu/Debian:**

```bash
sudo apt-get update
sudo apt-get install postgresql-16 postgresql-contrib-16
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

**No macOS (com Homebrew):**

```bash
brew install postgresql@16
brew services start postgresql@16
```

#### 5. Instalar Redis

**No Ubuntu/Debian:**

```bash
sudo apt-get install redis-server
sudo systemctl start redis-server
sudo systemctl enable redis-server
```

**No macOS (com Homebrew):**

```bash
brew install redis
brew services start redis
```

#### 6. Instalar Dependências do Projeto

```bash
# Instalar gems Ruby
bundle install

# Instalar pacotes Node.js
pnpm install
```

#### 7. Configurar Banco de Dados

```bash
# Criar banco de dados
bundle exec rails db:create

# Executar migrações
bundle exec rails db:migrate

# (Opcional) Gerar chaves de criptografia
bundle exec rails db:encryption:init
```

#### 8. Seeds de Dados (Opcional)

```bash
# Dados mínimos para testes rápidos
bundle exec rails db:seed

# OU dados volumosos para testes de busca/performance
bundle exec rails search:setup_test_data
```

## ▶️ Iniciar o Desenvolvimento

### Opção 1: Com overmind (Procfile)

```bash
# Instalar overmind (se não tiver)
gem install overmind

# Iniciar todos os serviços
overmind start -f ./Procfile.dev
```

### Opção 2: Com pnpm (Recomendado se não tiver overmind)

```bash
pnpm dev
```

### Opção 3: Servições Individuais (para debugging)

Em terminais diferentes:

```bash
# Terminal 1: Backend Rails
bundle exec rails s -p 3000

# Terminal 2: Worker Sidekiq
bundle exec sidekiq -C config/sidekiq.yml

# Terminal 3: Vite Dev Server
bin/vite dev
```

## 🌐 Acessar a Aplicação

Após iniciar os serviços:

- **Aplicação**: http://localhost:3000
- **Vite Dev Server**: http://localhost:3036
- **MailHog (Testes de Email)**: http://localhost:1025

## 🧪 Testes

### Backend (Ruby/RSpec)

```bash
# Rodar todos os testes
bundle exec rspec

# Rodar um arquivo específico
bundle exec rspec spec/path/to/file_spec.rb

# Rodar uma linha específica do teste
bundle exec rspec spec/path/to/file_spec.rb:42

# Com modo watch (auto-rerun ao mudar código)
bundle exec rspec --watch
```

### Frontend (Vue/Vitest)

```bash
# Rodar todos os testes
pnpm test

# Modo watch
pnpm test --watch

# Teste em arquivo específico
pnpm test src/components/MyComponent.test.js
```

### Linting

```bash
# Ruby/RuboCop
bundle exec rubocop -a  # Executa auto-fix

# JavaScript/ESLint
pnpm eslint          # Verificar
pnpm eslint:fix      # Auto-fix
```

## 📦 Usar Docker Compose (Alternativa)

Se preferir usar Docker para PostgreSQL e Redis:

```bash
# Iniciar serviços Docker
docker-compose up -d postgres redis mailhog

# Defina as variáveis de ambiente no .env:
# POSTGRES_HOST=localhost
# REDIS_URL=redis://localhost:6379

# Continue com os passos acima (gems, pnpm, migrations)
```

## 🔧 Variáveis de Ambiente

Um arquivo `.env` foi criado automaticamente com configurações padrão. Personalize conforme necessário:

```bash
# Abrir e editar
nano .env

# Variáveis principais:
# - FRONTEND_URL: URL da aplicação (padrão: http://localhost:3000)
# - POSTGRES_HOST: Host do PostgreSQL (padrão: localhost)
# - REDIS_URL: URL do Redis (padrão: redis://localhost:6379)
# - DEFAULT_LOCALE: Idioma padrão (pt_BR para português brasileiro)
# - ENABLE_ACCOUNT_SIGNUP: Permitir novos registros (padrão: false)
```

## 🛠️ Troubleshooting

### Erro: "Banco de dados não existe"

```bash
bundle exec rails db:create
```

### Erro: "Migrações não aplicadas"

```bash
bundle exec rails db:migrate
bundle exec rails db:migrate:reset  # Reseta e recria
```

### Erro: "Conexão recusada - Redis"

```bash
# Verificar se Redis está rodando
redis-cli ping  # Deve retornar "PONG"

# Se não tiver rodando:
redis-server  # Iniciar Redis localmente
```

### Erro: "Conexão recusada - PostgreSQL"

```bash
# Verificar status
sudo systemctl status postgresql

# Se não tiver rodando:
sudo systemctl start postgresql
```

### Erro de compilação Node (node-gyp)

```bash
# Instalar ferramentas de build necessárias
# Ubuntu/Debian:
sudo apt-get install build-essential python3

# macOS:
xcode-select --install
```

### Porta 3000 já está em uso

```bash
# Encontrar qual processo está usando a porta
lsof -i :3000

# Matar o processo
kill -9 <PID>

# Ou usar uma porta diferente
bundle exec rails s -p 3001
```

## 📚 Documentação Adicional

- **Stack Oficial**: Veja [CLAUDE.md](CLAUDE.md)
- **Instruções GitHub Copilot**: Veja [.github/copilot-instructions.md](.github/copilot-instructions.md)
- **Guia de Contribuição**: Veja [CONTRIBUTING.md](CONTRIBUTING.md)
- **Documentação Chatwoot**: https://www.chatwoot.com/help-center

## ✅ Checklist de Verificação

Após seguir os passos acima, marque cada item:

- [ ] Ruby 3.4.4 instalado e ativo
- [ ] Node.js 24.13.0 instalado e ativo
- [ ] PostgreSQL 16 instalado e rodando
- [ ] Redis instalado e rodando
- [ ] Dependências instaladas (bundle install, pnpm install)
- [ ] Banco de dados criado e migrado
- [ ] Servidor de desenvolvimento iniciando sem erros
- [ ] Acesso a http://localhost:3000 funciona
- [ ] Tests passam (bundle exec rspec, pnpm test)

## 🎯 Próximas Ações

1. **Criar uma conta de teste**: Acesse http://localhost:3000 e crie uma conta
2. **Explorar a interface**: Familiarize-se com a estrutura do projeto
3. **Ler o manifesto**: Consulte [CLAUDE.md](CLAUDE.md) para padrões de desenvolvimento
4. **Criar uma branch**: `git flow feature start nova-feature`
5. **Desenvolver com confiança**: Siga os padrões documentados

---

**Última atualização**: 25 de março de 2026

Para suporte, consulte a documentação oficial ou crie uma issue no repositório.
