# 🚀 Guia para Executar o Chatwoot Localmente

Este guia mostra como configurar e executar o projeto Chatwoot em sua máquina Windows para desenvolvimento local.

## 📋 Pré-requisitos

### 1. Instalar Ruby
- Instale Ruby 3.4.4 (versão específica do projeto)
- Recomendação: Use [RubyInstaller](https://rubyinstaller.org/) para Windows
```powershell
# Verificar versão após instalação
ruby --version
```

### 2. Instalar PostgreSQL
- Baixe e instale PostgreSQL: https://www.postgresql.org/download/windows/
- Durante instalação, anote a senha do usuário `postgres`
- Certifique-se que o serviço PostgreSQL está rodando

### 3. Instalar Redis
- Baixe Redis para Windows: https://github.com/microsoftarchive/redis/releases
- Ou use Docker: `docker run -d -p 6379:6379 redis:alpine`

### 4. Instalar Node.js
- Instale Node.js 23.x: https://nodejs.org/
- Instale pnpm globalmente:
```powershell
npm install -g pnpm@10.x
```

## ⚙️ Configuração do Projeto

### 1. Navegar para o diretório
```powershell
cd chatwoot
```

### 2. Instalar dependências Ruby
```powershell
# Instalar bundler se não tiver
gem install bundler

# Instalar dependências
bundle install
```

### 3. Instalar dependências JavaScript
```powershell
pnpm install
```

### 4. Configurar variáveis de ambiente
Crie um arquivo `.env` na raiz do projeto:
```powershell
New-Item -Path ".env" -ItemType File
```

Adicione as seguintes configurações no arquivo `.env`:
```env
# Banco de dados
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_USERNAME=postgres
POSTGRES_PASSWORD=sua_senha_postgres
POSTGRES_DATABASE=chatwoot_dev

# Redis
REDIS_URL=redis://localhost:6379

# Rails
RAILS_ENV=development
SECRET_KEY_BASE=sua_chave_secreta_aqui
FRONTEND_URL=http://localhost:3000

# Mailer (opcional para desenvolvimento)
MAILER_SENDER_EMAIL=noreply@chatwoot.dev
SMTP_ADDRESS=localhost
SMTP_PORT=1025

# Configurações adicionais
RAILS_LOG_TO_STDOUT=true
RAILS_MAX_THREADS=5
```

### 5. Gerar chave secreta
```powershell
# Gerar SECRET_KEY_BASE
bundle exec rails secret
```
Copie a chave gerada e adicione no arquivo `.env`

### 6. Preparar banco de dados
```powershell
# Criar banco de dados
bundle exec rails db:create

# Executar migrações
bundle exec rails db:migrate

# Carregar dados iniciais (opcional)
bundle exec rails db:seed
```

## 🚀 Executando o Projeto

### Opção 1: Usando Foreman (Recomendado)
```powershell
# Executar todos os serviços
pnpm run start:dev
```

### Opção 2: Executar serviços separadamente

#### Terminal 1 - Servidor Rails:
```powershell
bundle exec rails server -p 3000
```

#### Terminal 2 - Vite (Frontend):
```powershell
npx vite dev
```

#### Terminal 3 - Sidekiq (Jobs em background):
```powershell
bundle exec sidekiq
```

## 🌐 Acessando a Aplicação

Após executar os comandos acima:
- **Frontend**: http://localhost:3000
- **API**: http://localhost:3000/api
- **Admin**: http://localhost:3000/super_admin

## 👤 Criando Usuário Administrador

```powershell
# Abrir console Rails
bundle exec rails console

# Criar conta e usuário
account = Account.create!(name: "Minha Empresa")
user = User.create!(
  name: "Admin",
  email: "admin@example.com",
  password: "123456",
  password_confirmation: "123456",
  confirmed_at: Time.current
)
AccountUser.create!(account: account, user: user, role: "administrator")
```

## 🛠️ Comandos Úteis

### Desenvolvimento
```powershell
# Executar testes
pnpm test

# Linter JavaScript
pnpm run eslint

# Linter Ruby
bundle exec rubocop

# Verificar dependências
bundle exec rails middleware
```

### Banco de dados
```powershell
# Reset completo do banco
bundle exec rails db:drop db:create db:migrate db:seed

# Console do banco
bundle exec rails dbconsole

# Console Rails
bundle exec rails console
```

## 🔧 Solução de Problemas

### Erro de conexão PostgreSQL
- Verifique se PostgreSQL está rodando
- Confirme usuário/senha no `.env`
- Teste conexão: `psql -U postgres -h localhost`

### Erro de permissão Ruby
```powershell
# Instalar bundler localmente
gem install bundler --user-install
```

### Porta já em uso
```powershell
# Verificar processos na porta 3000
netstat -ano | findstr :3000

# Matar processo (substitua PID)
taskkill /F /PID numero_do_pid
```

### Problemas com Vite/Node
```powershell
# Limpar cache
pnpm store prune
rm -rf node_modules
pnpm install
```

## 🎯 Próximos Passos

1. Explore a documentação em: http://localhost:3000/help-center
2. Configure integrações (Slack, WhatsApp, etc.) conforme necessário
3. Personalize a interface através das configurações de conta

## 📚 Recursos Adicionais

- **Documentação oficial**: https://www.chatwoot.com/help-center
- **Código fonte**: https://github.com/chatwoot/chatwoot
- **Discord da comunidade**: https://discord.gg/cJXdrwS

---
**Nota**: Este é um ambiente de desenvolvimento. Para produção, consulte a documentação oficial de deployment. 