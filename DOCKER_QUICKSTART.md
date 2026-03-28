# 🐳 Chatwoot - Guia Rápido Docker

Guia completo para rodar o Chatwoot com Docker Compose em desenvolvimento.

## 📋 Pré-requisitos

- Docker (v20+)
- Docker Compose (v2+)
- 8GB RAM mínimo
- 10GB espaço em disco

Verificar instalação:
```bash
docker --version
docker-compose --version
```

---

## 🚀 Início Rápido (3 passos)

### 1. Configurar Variáveis de Ambiente
```bash
# Copiar arquivo de exemplo
cp .env.docker .env

# Gerar SECRET_KEY_BASE seguro
openssl rand -hex 64

# Editar .env e substituir SECRET_KEY_BASE
nano .env  # ou vim, code, etc
```

### 2. Subir Infraestrutura
```bash
# Subir todos os serviços
docker-compose up -d

# Ver logs em tempo real
docker-compose logs -f
```

### 3. Preparar Banco de Dados
```bash
# Criar e migrar banco
docker-compose exec rails bundle exec rails db:create db:migrate

# Criar usuário admin padrão (opcional)
docker-compose exec rails bundle exec rails db:seed
```

**Pronto!** Acesse: http://localhost:3000

---

## 🎯 Acesso Rápido

| Serviço | URL | Descrição |
|---------|-----|-----------|
| **Chatwoot Web** | http://localhost:3000 | Aplicação principal |
| **Vite Dev Server** | http://localhost:3036 | Frontend dev server |
| **MailHog** | http://localhost:8025 | Ver emails de teste |
| **PostgreSQL** | localhost:5432 | Banco de dados |
| **Redis** | localhost:6379 | Cache/jobs |

### Credenciais Padrão (após seed)
```
Email: admin@chatwoot.com (ou criado no primeiro acesso)
Senha: 123456 (ou definida no signup)
```

---

## 📦 Serviços do Docker Compose

O `docker-compose.yaml` configura 6 serviços:

### 1. **postgres** (pgvector/pgvector:pg16)
- Banco de dados principal
- Porta: 5432
- Volume: `postgres` (dados persistentes)
- Database: `chatwoot`

### 2. **redis** (redis:alpine)
- Cache e fila de jobs
- Porta: 6379
- Volume: `redis` (dados persistentes)

### 3. **rails** (chatwoot-rails:development)
- Servidor Rails/Puma
- Porta: 3000
- Monta código local (`./:/app`)
- Roda: `rails s -p 3000`

### 4. **sidekiq** (chatwoot-rails:development)
- Background jobs worker
- Processa filas assíncronas
- Mesmo container do Rails

### 5. **vite** (chatwoot-vite:development)
- Dev server frontend
- Porta: 3036
- Hot reload automático
- Assets compilados em `/app/public/packs`

### 6. **mailhog** (mailhog/mailhog)
- SMTP fake para desenvolvimento
- Web UI: 8025
- SMTP: 1025
- Captura todos os emails

---

## 🛠️ Comandos Úteis

### Gerenciar Serviços
```bash
# Subir todos os serviços
docker-compose up

# Subir em background
docker-compose up -d

# Ver logs de todos os serviços
docker-compose logs -f

# Ver logs de um serviço específico
docker-compose logs -f rails

# Parar todos os serviços
docker-compose stop

# Parar e remover containers
docker-compose down

# Parar e remover containers + volumes (⚠️ apaga dados!)
docker-compose down -v

# Restart de um serviço
docker-compose restart rails

# Ver status dos serviços
docker-compose ps
```

### Rails Console & Comandos
```bash
# Abrir Rails console
docker-compose exec rails bundle exec rails console

# Rodar migrations
docker-compose exec rails bundle exec rails db:migrate

# Rollback última migration
docker-compose exec rails bundle exec rails db:rollback

# Seed dados de teste
docker-compose exec rails bundle exec rails db:seed

# Criar conta e usuário manualmente
docker-compose exec rails bundle exec rails runner "
  user = User.create!(
    email: 'admin@example.com',
    password: 'Password123!',
    name: 'Admin User',
    confirmed_at: Time.current
  )
  account = Account.create!(name: 'My Company')
  AccountUser.create!(
    account: account,
    user: user,
    role: :administrator
  )
  puts 'User created! Login: admin@example.com / Password123!'
"

# Ver status das migrations
docker-compose exec rails bundle exec rails db:migrate:status
```

### Testes
```bash
# Preparar banco de testes
docker-compose exec rails RAILS_ENV=test bundle exec rails db:test:prepare

# Rodar todos os testes
docker-compose exec rails bundle exec rspec

# Rodar teste específico
docker-compose exec rails bundle exec rspec spec/models/account_user_spec.rb

# Rodar testes com output detalhado
docker-compose exec rails bundle exec rspec -fd

# Rodar testes de uma feature específica
docker-compose exec rails bundle exec rspec --example "participating"
```

### Linting
```bash
# RuboCop (Ruby)
docker-compose exec rails bundle exec rubocop

# RuboCop com auto-fix
docker-compose exec rails bundle exec rubocop -a

# ESLint (JavaScript/Vue)
docker-compose exec rails pnpm eslint

# ESLint com auto-fix
docker-compose exec rails pnpm eslint:fix
```

### Bash/Shell
```bash
# Abrir bash no container Rails
docker-compose exec rails bash

# Rodar comando único
docker-compose exec rails bash -c "ls -la app/models"

# Executar como root (para instalar pacotes)
docker-compose exec -u root rails bash
```

### NPM/Pnpm
```bash
# Instalar dependências
docker-compose exec rails pnpm install

# Adicionar pacote
docker-compose exec rails pnpm add <package-name>

# Rodar script
docker-compose exec rails pnpm run <script-name>
```

### Banco de Dados
```bash
# Acessar PostgreSQL
docker-compose exec postgres psql -U postgres -d chatwoot

# Backup do banco
docker-compose exec postgres pg_dump -U postgres chatwoot > backup.sql

# Restaurar backup
docker-compose exec -T postgres psql -U postgres chatwoot < backup.sql

# Resetar banco (⚠️ apaga tudo!)
docker-compose exec rails bundle exec rails db:drop db:create db:migrate db:seed
```

### Redis
```bash
# Abrir Redis CLI
docker-compose exec redis redis-cli

# Ver todas as chaves
docker-compose exec redis redis-cli KEYS '*'

# Limpar Redis
docker-compose exec redis redis-cli FLUSHALL
```

---

## 🔧 Troubleshooting

### Problema: Porta já em uso
```bash
# Ver quem está usando a porta 3000
lsof -i :3000

# Matar processo
kill -9 <PID>

# Ou mudar porta no docker-compose.yaml
ports:
  - "3001:3000"  # Usar 3001 no host
```

### Problema: Containers não iniciam
```bash
# Ver logs de erro
docker-compose logs

# Rebuild containers
docker-compose build --no-cache
docker-compose up -d

# Limpar tudo e recomeçar
docker-compose down -v
docker system prune -a
docker-compose up -d
```

### Problema: Banco não conecta
```bash
# Verificar se PostgreSQL está rodando
docker-compose ps postgres

# Ver logs do PostgreSQL
docker-compose logs postgres

# Testar conexão
docker-compose exec postgres psql -U postgres -c "SELECT 1"

# Recriar volume do PostgreSQL
docker-compose down -v
docker-compose up -d postgres
sleep 5
docker-compose exec rails bundle exec rails db:create db:migrate
```

### Problema: Assets não carregam
```bash
# Restart Vite
docker-compose restart vite

# Ver logs do Vite
docker-compose logs -f vite

# Limpar cache
docker-compose exec vite rm -rf node_modules/.vite
docker-compose restart vite

# Rebuild assets
docker-compose exec vite pnpm run build
```

### Problema: Redis connection refused
```bash
# Verificar Redis
docker-compose exec redis redis-cli ping
# Deve retornar: PONG

# Ver logs
docker-compose logs redis

# Limpar e restart
docker-compose restart redis
```

### Problema: Sidekiq não processa jobs
```bash
# Ver status do Sidekiq
docker-compose logs sidekiq

# Restart Sidekiq
docker-compose restart sidekiq

# Ver filas no Redis
docker-compose exec redis redis-cli
> KEYS *sidekiq*

# Limpar filas
docker-compose exec rails bundle exec rails runner "Sidekiq::Queue.all.each(&:clear)"
```

### Problema: Emails não aparecem no MailHog
```bash
# Verificar MailHog está rodando
docker-compose ps mailhog

# Acessar web UI
open http://localhost:8025

# Testar envio manual
docker-compose exec rails bundle exec rails runner "
  UserMailer.with(user: User.first).confirmation_instructions.deliver_now
"
```

### Problema: Performance lenta
```bash
# Ver uso de recursos
docker stats

# Aumentar recursos no Docker Desktop:
# Settings → Resources → Memory (mínimo 4GB, recomendado 8GB)

# Limpar volumes não usados
docker volume prune

# Limpar cache do Rails
docker-compose exec rails bundle exec rails tmp:clear
```

---

## 🏗️ Build Customizado

### Rebuild containers
```bash
# Rebuild todos
docker-compose build

# Rebuild sem cache
docker-compose build --no-cache

# Rebuild serviço específico
docker-compose build rails
```

### Modificar Dockerfiles
```
docker/
├── Dockerfile                    # Base image
├── dockerfiles/
│   ├── rails.Dockerfile         # Rails container
│   └── vite.Dockerfile          # Vite container
└── entrypoints/
    ├── rails.sh                 # Rails entrypoint
    └── vite.sh                  # Vite entrypoint
```

---

## 📊 Monitoramento

### Logs em tempo real
```bash
# Todos os serviços
docker-compose logs -f

# Filtrar por serviço
docker-compose logs -f rails sidekiq

# Últimas 100 linhas
docker-compose logs --tail=100 rails

# Desde timestamp
docker-compose logs --since 2024-03-27T10:00:00 rails
```

### Métricas
```bash
# Uso de recursos
docker stats

# Espaço em disco
docker system df

# Inspecionar container
docker inspect chatwoot_rails_1
```

---

## 🧹 Limpeza

### Limpar ambiente de desenvolvimento
```bash
# Parar containers
docker-compose down

# Remover volumes (⚠️ apaga dados!)
docker-compose down -v

# Limpar imagens não usadas
docker image prune -a

# Limpar tudo do Docker
docker system prune -a --volumes
```

### Resetar projeto do zero
```bash
# 1. Parar e remover tudo
docker-compose down -v

# 2. Limpar Docker
docker system prune -af --volumes

# 3. Rebuild e subir
docker-compose build --no-cache
docker-compose up -d

# 4. Preparar banco
docker-compose exec rails bundle exec rails db:create db:migrate db:seed
```

---

## 🎓 Workflow de Desenvolvimento

### 1. **Início do Dia**
```bash
# Subir ambiente
docker-compose up -d

# Ver se tudo está ok
docker-compose ps

# Atualizar dependências
docker-compose exec rails bundle install
docker-compose exec rails pnpm install

# Rodar migrations pendentes
docker-compose exec rails bundle exec rails db:migrate
```

### 2. **Durante Desenvolvimento**
```bash
# Ver logs em outra janela
docker-compose logs -f rails vite

# Hot reload funcionando:
# - Rails: auto-reload ao salvar .rb
# - Vite: hot-reload ao salvar .vue/.js

# Rodar testes ao fazer mudanças
docker-compose exec rails bundle exec rspec spec/path/to/spec.rb
```

### 3. **Antes de Commit**
```bash
# Rodar linters
docker-compose exec rails bundle exec rubocop -a
docker-compose exec rails pnpm eslint:fix

# Rodar testes
docker-compose exec rails bundle exec rspec

# Verificar migrations
docker-compose exec rails bundle exec rails db:migrate:status
```

### 4. **Fim do Dia**
```bash
# Parar serviços (mantém dados)
docker-compose stop

# Ou remover containers (mantém volumes)
docker-compose down
```

---

## 🔐 Segurança (Produção)

⚠️ **IMPORTANTE**: O `.env.docker` é para **DESENVOLVIMENTO APENAS**!

Para produção:
1. ✅ Gerar SECRET_KEY_BASE único: `openssl rand -hex 64`
2. ✅ Definir senhas fortes para PostgreSQL e Redis
3. ✅ Habilitar SSL: `FORCE_SSL=true`
4. ✅ Configurar SMTP real (não MailHog)
5. ✅ Usar S3 ou similar para uploads
6. ✅ Configurar CORS adequadamente
7. ✅ Desabilitar signups públicos se necessário
8. ✅ Configurar backups automatizados
9. ✅ Usar secrets management (Vault, AWS Secrets, etc)
10. ✅ Habilitar monitoramento (Sentry, New Relic, etc)

---

## 📚 Recursos Adicionais

- [Documentação Oficial Chatwoot](https://www.chatwoot.com/docs)
- [Docker Compose Reference](https://docs.docker.com/compose/)
- [PostgreSQL Docker](https://hub.docker.com/_/postgres)
- [Redis Docker](https://hub.docker.com/_/redis)

---

## ❓ FAQ

### P: Como adicionar um novo serviço ao docker-compose?
**R:** Edite `docker-compose.yaml` e adicione um novo service. Exemplo:
```yaml
elasticsearch:
  image: elasticsearch:8
  ports:
    - "9200:9200"
  environment:
    - discovery.type=single-node
  volumes:
    - elasticsearch:/usr/share/elasticsearch/data
```

### P: Como usar um banco PostgreSQL externo?
**R:** No `.env`, altere:
```bash
POSTGRES_HOST=seu-host.com
POSTGRES_PORT=5432
POSTGRES_PASSWORD=sua-senha
```
E comente o serviço `postgres` no docker-compose.yaml.

### P: Como debugar com binding.pry?
**R:**
```bash
# Parar Rails normal
docker-compose stop rails

# Rodar Rails interativo
docker-compose run --rm --service-ports rails

# Agora binding.pry vai funcionar!
```

### P: Como fazer hot reload funcionar no Windows/WSL?
**R:** Adicione ao `docker-compose.yaml`:
```yaml
rails:
  environment:
    - WATCHPACK_POLLING=true
```

### P: Posso rodar em produção com docker-compose?
**R:** Não é recomendado. Use:
- Kubernetes (k8s)
- Docker Swarm
- AWS ECS/Fargate
- Heroku
- Railway
- Render

---

**Criado em**: 2026-03-27
**Versão Chatwoot**: Latest (development)
**Docker Compose**: v2+

---

## 🚀 Quick Commands Cheat Sheet

```bash
# START
docker-compose up -d && docker-compose logs -f

# STOP
docker-compose down

# RESTART
docker-compose restart rails

# CONSOLE
docker-compose exec rails bundle exec rails console

# TESTS
docker-compose exec rails bundle exec rspec

# LOGS
docker-compose logs -f rails

# CLEAN
docker-compose down -v && docker system prune -af

# REBUILD
docker-compose build --no-cache && docker-compose up -d
```

**Dúvidas?** Veja os logs: `docker-compose logs -f`
