# 🚀 Guia de Migração Chatwoot v3 → v4

Este guia descreve como migrar um backup do Chatwoot v3 para o Chatwoot v4 em produção.

## 📋 Visão Geral do Problema

Quando você restaura um backup do **Chatwoot v3** em um ambiente **Chatwoot v4**, ocorrem erros porque:

- ❌ A coluna `settings` não existe na tabela `accounts`
- ❌ A coluna `csat_config` não existe na tabela `inboxes`  
- ❌ Há 26+ migrações pendentes que precisam ser executadas

## 🛠️ Soluções Disponíveis

### 1️⃣ **Automática (Recomendada)** - Script PowerShell

```powershell
# Executa migração completa com backup automático
.\migrate-production.ps1

# Com parâmetros customizados
.\migrate-production.ps1 -ComposeFile "docker-compose.yml" -ProjectName "meu-projeto"

# Pular backup (não recomendado)
.\migrate-production.ps1 -SkipBackup

# Forçar execução sem confirmações
.\migrate-production.ps1 -Force
```

### 2️⃣ **Task do Rails** - Dentro do Container

```bash
# Entrar no container Rails
docker-compose exec rails bash

# Executar migração
bundle exec rails db:chatwit_migrate

# OU usar o comando preparar (inclui seeds em dev)
bundle exec rails db:chatwit_prepare
```

### 3️⃣ **Manual** - Script Ruby Detalhado

```bash
# Copiar script para container
docker cp migrate-chatwoot-v3-to-v4.rb container_rails:/tmp/

# Executar dentro do container
docker-compose exec rails bundle exec rails runner /tmp/migrate-chatwoot-v3-to-v4.rb
```

## 🔥 Processo para Produção (Passo a Passo)

### **Pré-requisitos:**
- ✅ Backup do Chatwoot v3 já restaurado no PostgreSQL
- ✅ Chatwoot v4 buildado e em execução
- ✅ Acesso aos scripts de migração

### **Passo 1: Preparação**

```powershell
# 1. Fazer backup atual (segurança)
docker-compose exec postgres pg_dump -U postgres chatwoot > backup_pre_migration.sql

# 2. Verificar se containers estão rodando
docker-compose ps
```

### **Passo 2: Executar Migração**

**Opção A - Automática (Recomendada):**
```powershell
.\migrate-production.ps1
```

**Opção B - Manual:**
```powershell
# 1. Copiar scripts para o container
docker cp migrate-chatwoot-v3-to-v4.rb rails_container:/tmp/
docker cp lib/tasks/chatwit_migrate.rake rails_container:/app/lib/tasks/

# 2. Executar migração
docker-compose exec rails bundle exec rails db:chatwit_migrate
```

### **Passo 3: Verificação**

```powershell
# 1. Reiniciar containers
docker-compose restart rails sidekiq

# 2. Verificar logs
docker-compose logs rails --tail=50

# 3. Testar aplicação
# Acessar http://seu-dominio.com e fazer login
```

## 🔍 Resolução de Problemas

### **Erro: "column already exists"**
```bash
# A coluna já foi adicionada, continuar normalmente
# O script lida com isso automaticamente
```

### **Erro: "relation does not exist"**
```bash
# Verificar se o banco correto está sendo usado
docker-compose exec rails bundle exec rails runner "puts ActiveRecord::Base.connection.current_database"

# Deve retornar: chatwoot
```

### **Erro: "migrations pending"**
```bash
# Verificar status das migrações
docker-compose exec rails bundle exec rails db:migrate:status

# Executar migrações pendentes
docker-compose exec rails bundle exec rails db:migrate
```

## 📦 Estrutura de Arquivos

```
/
├── migrate-production.ps1           # Script principal de migração
├── migrate-chatwoot-v3-to-v4.rb    # Script Ruby detalhado  
├── lib/tasks/chatwit_migrate.rake   # Tasks customizadas do Rails
├── build-producao.ps1              # Build da imagem Docker
├── Dockerfile.enterprise           # Dockerfile para produção
└── MIGRAÇÃO-V3-TO-V4.md            # Este guia
```

## 🛡️ Segurança

### **Backups Automáticos:**
- 📦 O script cria backup automático antes da migração
- 💾 Salvo em `./backups/pre_migration_backup_YYYYMMDD_HHMMSS.sql.gz`

### **Rollback (se necessário):**
```bash
# 1. Parar aplicação
docker-compose stop rails sidekiq

# 2. Restaurar backup
gunzip -c backup_pre_migration.sql.gz | docker-compose exec -T postgres psql -U postgres -d chatwoot

# 3. Reiniciar aplicação
docker-compose start rails sidekiq
```

## ✅ Checklist de Verificação Pós-Migração

- [ ] Aplicação carrega sem erros
- [ ] Login funciona com credenciais existentes
- [ ] Dados das contas estão preservados
- [ ] Mensagens e conversas aparecem
- [ ] Widgets funcionam nos sites
- [ ] Notificações funcionam
- [ ] Integrações (email, WhatsApp, etc.) funcionam

## 🎯 Comandos Úteis

```bash
# Verificar versão do Chatwoot
docker-compose exec rails bundle exec rails runner "puts Chatwoot.config[:version]"

# Verificar tabelas e colunas
docker-compose exec postgres psql -U postgres -d chatwoot -c "\d accounts"
docker-compose exec postgres psql -U postgres -d chatwoot -c "\d inboxes"

# Estatísticas do banco
docker-compose exec rails bundle exec rails runner "
puts 'Contas: ' + Account.count.to_s
puts 'Usuários: ' + User.count.to_s  
puts 'Mensagens: ' + Message.count.to_s
puts 'Conversas: ' + Conversation.count.to_s
"

# Verificar logs em tempo real
docker-compose logs -f rails
```

## 📞 Suporte

Se encontrar problemas:

1. **Verificar logs:** `docker-compose logs rails --tail=100`
2. **Entrar no container:** `docker-compose exec rails bash`
3. **Executar Rails console:** `bundle exec rails console`
4. **Verificar banco:** `docker-compose exec postgres psql -U postgres chatwoot`

---

⚡ **Migração bem-sucedida = Chatwoot v4 funcional com todos os dados preservados!** 🎉 