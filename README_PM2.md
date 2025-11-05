# Chatwoot com PM2 - Guia Completo

Este guia explica como configurar e executar o Chatwoot usando PM2.

## 🚀 Setup Rápido

Execute o script de setup completo:

```bash
./setup.sh
```

Este script irá:
- ✅ Verificar e instalar dependências
- ✅ Configurar PostgreSQL e Redis
- ✅ Criar e migrar banco de dados
- ✅ Preparar tudo para iniciar com PM2

## 📋 Pré-requisitos

- Ruby e Bundler instalados
- Node.js e pnpm instalados
- PM2 instalado: `npm install -g pm2`
- PostgreSQL instalado e rodando
- Redis instalado e rodando

## 🔧 Configuração Manual (se necessário)

### 1. Variáveis de Ambiente

Edite o arquivo `.env` com as seguintes configurações:

```bash
# Rails
RAILS_ENV=development
SECRET_KEY_BASE=<gerado automaticamente>
FRONTEND_URL=http://0.0.0.0:3000

# PostgreSQL
POSTGRES_HOST=localhost
POSTGRES_USERNAME=postgres
POSTGRES_PASSWORD=sua_senha
POSTGRES_DATABASE=chatwoot_development

# Redis
REDIS_URL=redis://127.0.0.1:6379
```

### 2. Configurar Senha do PostgreSQL

Se necessário, configure a senha:

```bash
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'sua_senha';"
```

Depois atualize o `.env` com a mesma senha.

## 🎯 Comandos PM2

### Iniciar
```bash
pm2 start ecosystem.config.js
```

### Ver Status
```bash
pm2 status
```

### Ver Logs
```bash
# Todos os logs
pm2 logs

# Logs do servidor web
pm2 logs chatwoot-web

# Logs do worker
pm2 logs chatwoot-worker
```

### Gerenciar Processos
```bash
# Reiniciar
pm2 restart ecosystem.config.js

# Parar
pm2 stop ecosystem.config.js

# Deletar
pm2 delete ecosystem.config.js

# Salvar configuração (para iniciar no boot)
pm2 save
pm2 startup
```

## 📁 Estrutura de Arquivos

- `setup.sh` - Script completo de setup (execute uma vez)
- `ecosystem.config.js` - Configuração do PM2
- `bin/pm2-web.sh` - Script do servidor web
- `bin/pm2-worker.sh` - Script do worker Sidekiq
- `.env` - Variáveis de ambiente

## 🔍 Verificação

### Verificar Status dos Serviços

```bash
# PostgreSQL
pg_isready -h localhost

# Redis
redis-cli ping

# PM2
pm2 status

# Banco de dados
bundle exec rails db:version
```

### Acessar o Chatwoot

Após iniciar com PM2, acesse:
- **URL**: http://localhost:3000
- **Status**: Verifique com `curl http://localhost:3000`

## 🐛 Troubleshooting

### Erro de conexão com PostgreSQL
- Verifique se está rodando: `sudo systemctl status postgresql`
- Teste conexão: `psql -h localhost -U postgres -d postgres`
- Verifique credenciais no `.env`

### Erro de conexão com Redis
- Verifique se está rodando: `redis-cli ping`
- Inicie se necessário: `sudo systemctl start redis-server`

### Erro ao iniciar com PM2
- Verifique logs: `pm2 logs`
- Verifique dependências: `bundle check && pnpm install`
- Verifique permissões: `chmod +x bin/pm2-*.sh`

### Processos não iniciam
```bash
# Ver logs detalhados
pm2 logs --lines 50

# Reiniciar tudo
pm2 delete all
pm2 start ecosystem.config.js
```

## 📊 Status Atual

Para verificar o status atual:

```bash
pm2 status
bundle exec rails db:version
redis-cli ping
```

## 🔄 Atualizar

Para atualizar o Chatwoot:

```bash
# Parar processos
pm2 stop ecosystem.config.js

# Atualizar código
git pull

# Atualizar dependências
bundle install
pnpm install

# Executar migrações
bundle exec rails db:migrate

# Reiniciar
pm2 restart ecosystem.config.js
```

## 📝 Notas

- Os logs são salvos em `./log/pm2-*.log`
- O ambiente padrão é `development` (ajuste no `.env` para produção)
- O servidor escuta em `0.0.0.0:3000` por padrão
- Para produção, ajuste `RAILS_ENV=production` e configure `SECRET_KEY_BASE` adequadamente

