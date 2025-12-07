# CommMate Chatwoot - Guia de Desenvolvimento Local

Este guia explica como iniciar o CommMate Chatwoot no ambiente de desenvolvimento local usando PostgreSQL e Redis rodando no Podman.

## Pré-requisitos

### Serviços Obrigatórios (Rodando no Podman)
- **PostgreSQL 16+** rodando na porta 5432
- **Redis** rodando na porta 6379

### Ferramentas de Desenvolvimento
- **Ruby 3.4.4** (gerenciado via rbenv)
- **Node.js 23.x** (recomendado) ou 24.x
- **pnpm** para gerenciamento de pacotes JavaScript
- **overmind** para gerenciamento de processos

## Instalação das Dependências

### 1. Instalar Ruby via rbenv

```bash
# Verificar se o rbenv está instalado
which rbenv

# O Ruby 3.4.4 já deve estar disponível
rbenv versions
```

### 2. Instalar Overmind

```bash
brew install overmind
```

### 3. Instalar Dependências do Projeto

```bash
cd /Users/schimuneck/projects/commmmate/chatwoot

# Instalar gems Ruby
export PATH="$HOME/.rbenv/shims:$PATH"
bundle install

# Instalar pacotes Node.js
pnpm install
```

## Configuração do Ambiente

### Criar arquivo .env

Crie o arquivo `.env` na raiz do projeto com as seguintes variáveis:

```bash
# Database Configuration
POSTGRES_DATABASE=chatwoot
POSTGRES_PASSWORD=postgres
POSTGRES_HOST=127.0.0.1
POSTGRES_PORT=5432
POSTGRES_USERNAME=postgres
DATABASE_URL=postgresql://postgres:postgres@127.0.0.1:5432/chatwoot

# Redis Configuration
REDIS_URL=redis://localhost:6379

# Development Configuration
DISABLE_MINI_PROFILER=true
RAILS_ENV=development
NODE_ENV=development

# Required for Chatwoot
SECRET_KEY_BASE=<gerar_com_openssl>
FRONTEND_URL=http://localhost:3000
```

Para gerar o `SECRET_KEY_BASE`:

```bash
openssl rand -hex 64
```

### Verificar Conectividade com Serviços

```bash
# Testar PostgreSQL
PGPASSWORD=postgres psql -h 127.0.0.1 -p 5432 -U postgres -d chatwoot -c "SELECT version();"

# Testar Redis (se redis-cli estiver instalado)
redis-cli ping
```

## Preparar o Banco de Dados

### Executar Migrações

```bash
cd /Users/schimuneck/projects/commmmate/chatwoot
export PATH="$HOME/.rbenv/shims:$PATH"
bundle exec rails db:migrate
```

**Nota**: O banco de dados `chatwoot` já deve existir no PostgreSQL do Podman. Não execute `db:create` ou `db:setup` para evitar recriar o banco.

## Iniciar o Servidor de Desenvolvimento

### Limpar Processos Antigos (se necessário)

```bash
# Remover arquivo PID antigo
rm -f tmp/pids/server.pid

# Matar processos Rails/Vite antigos (se existirem)
pkill -f 'rails|vite|sidekiq'
```

### Iniciar com Overmind

```bash
cd /Users/schimuneck/projects/commmmate/chatwoot
export PATH="$HOME/.rbenv/shims:$PATH"
overmind start -f ./Procfile.dev
```

Isso iniciará todos os serviços necessários:
- **backend**: Rails/Puma na porta 3000
- **worker**: Sidekiq para processamento de jobs em background
- **vite**: Servidor de desenvolvimento frontend na porta 3036

### Gerenciar Processos com Overmind

```bash
# Parar todos os serviços
overmind quit

# Ou pressione Ctrl+C no terminal

# Conectar a um processo específico para ver logs
overmind connect backend
overmind connect worker
overmind connect vite

# Pressione Ctrl+B seguido de D para desconectar sem parar o processo
```

## Verificar se Está Rodando

### Verificar Processos

```bash
# Verificar se todos os serviços estão rodando
ps aux | grep -E '(rails|sidekiq|vite)' | grep -v grep

# Verificar portas em uso
lsof -ti:3000  # Rails/Puma
lsof -ti:3036  # Vite
lsof -ti:7433  # Sidekiq health check
```

### Testar Acesso

```bash
# Testar backend
curl -I http://localhost:3000/

# Deve retornar HTTP 200 OK
```

### Acessar no Navegador

Abra seu navegador em:

```
http://localhost:3000
```

## Estrutura de Processos (Procfile.dev)

O arquivo `Procfile.dev` define os seguintes processos:

```
backend: bin/rails s -p 3000
worker: dotenv bundle exec sidekiq -C config/sidekiq.yml
vite: bin/vite dev
```

## Problemas Comuns

### Erro: "A server is already running"

```bash
# Remover arquivo PID
rm -f tmp/pids/server.pid

# Matar processo antigo
kill -9 $(lsof -ti:3000)
```

### Erro: "connection to server failed"

Verifique se o PostgreSQL está rodando no Podman:

```bash
podman ps | grep postgres
```

Se necessário, inicie o container do PostgreSQL.

### Erro: "Redis connection refused"

Verifique se o Redis está rodando no Podman:

```bash
podman ps | grep redis
```

Se necessário, inicie o container do Redis.

### Erro: "Ruby version mismatch"

Certifique-se de que o rbenv está carregado:

```bash
export PATH="$HOME/.rbenv/shims:$PATH"
ruby --version  # Deve mostrar 3.4.4
```

## Desenvolvimento

### Executar Testes

```bash
# Testes Ruby (RSpec)
bundle exec rspec

# Testes JavaScript (Vitest)
pnpm test
```

### Lint

```bash
# Lint Ruby
bundle exec rubocop -a

# Lint JavaScript/Vue
pnpm eslint
pnpm eslint:fix
```

### Acessar Console Rails

```bash
bundle exec rails console
```

### Acessar Banco de Dados

```bash
PGPASSWORD=postgres psql -h 127.0.0.1 -p 5432 -U postgres -d chatwoot
```

## Variáveis de Ambiente Importantes

| Variável | Descrição | Valor Padrão |
|----------|-----------|--------------|
| `POSTGRES_DATABASE` | Nome do banco de dados | `chatwoot` |
| `POSTGRES_HOST` | Host do PostgreSQL | `127.0.0.1` |
| `POSTGRES_PORT` | Porta do PostgreSQL | `5432` |
| `POSTGRES_USERNAME` | Usuário do PostgreSQL | `postgres` |
| `POSTGRES_PASSWORD` | Senha do PostgreSQL | `postgres` |
| `REDIS_URL` | URL de conexão do Redis | `redis://localhost:6379` |
| `SECRET_KEY_BASE` | Chave secreta do Rails | Gerar com `openssl rand -hex 64` |
| `FRONTEND_URL` | URL do frontend | `http://localhost:3000` |
| `DISABLE_MINI_PROFILER` | Desabilitar mini profiler | `true` |

## Portas Utilizadas

| Serviço | Porta | Descrição |
|---------|-------|-----------|
| Rails/Puma | 3000 | Backend API e páginas web |
| Vite | 3036 | Servidor de desenvolvimento frontend |
| Sidekiq Health | 7433 | Health check do Sidekiq |
| PostgreSQL | 5432 | Banco de dados (Podman) |
| Redis | 6379 | Cache e filas (Podman) |

## Logs

Os logs de desenvolvimento são exibidos no terminal onde o overmind está rodando. Você também pode encontrar logs em:

- `log/development.log` - Logs do Rails
- `log/sidekiq.log` - Logs do Sidekiq (se configurado)

## Dicas de Produtividade

### Usar tmux com Overmind

O Overmind usa tmux internamente. Você pode:

```bash
# Listar sessões tmux
tmux ls

# Conectar diretamente à sessão do Overmind
tmux attach -t chatwoot
```

### Reiniciar Apenas um Serviço

```bash
# Conectar ao processo
overmind connect backend

# Pressionar Ctrl+C para parar
# O Overmind reiniciará automaticamente
```

### Ver Logs em Tempo Real

```bash
# Rails
tail -f log/development.log

# Ou usar o overmind
overmind connect backend
```

## Referências

- [Chatwoot Development Guide](https://www.chatwoot.com/docs/contributing-guide)
- [Overmind Documentation](https://github.com/DarthSim/overmind)
- [Rails Guides](https://guides.rubyonrails.org/)

