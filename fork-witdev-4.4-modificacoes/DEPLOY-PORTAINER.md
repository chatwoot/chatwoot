# 🚀 Deploy Chatwit v4 no Portainer (Linux)

Este guia explica como fazer o build da imagem Docker do Chatwit v4 e fazer deploy no Portainer em ambiente Linux de produção.

## 📋 Pré-requisitos

- ✅ Windows com PowerShell (para build)
- ✅ Docker Desktop instalado
- ✅ Acesso ao Portainer em servidor Linux
- ✅ Domínio configurado para o Chatwit
- ✅ Servidor SMTP configurado
- ✅ Backup do Chatwoot v3 (se houver)

## 🔨 Passo 1: Build da Imagem Docker

### **1.1 Preparar Ambiente**
```powershell
# No Windows, navegue até o diretório do projeto
cd D:\ruby\chatwit

# Verificar se todos os arquivos estão presentes
ls migrate-chatwoot-v3-to-v4.rb, lib/tasks/chatwit_migrate.rake, Dockerfile.enterprise
```

### **1.2 Executar Build**
```powershell
# Build da imagem Enterprise com telemetria desabilitada e migração automática
.\build-producao.ps1 -Version "v4.3.1" -Latest -Enterprise -DisableTelemetry

# Output esperado:
# [BUILD] Building witrocha/chatwit with tags: v4.3.1, latest
# [SUCCESS] Build successful!
# [PRIVACY] TELEMETRIA DESABILITADA NA IMAGEM!
# Imagem inclui scripts de migração automática v3->v4
```

### **1.3 Push para Registry**
```powershell
# Login no Docker Hub
docker login

# Push das imagens
docker push witrocha/chatwit:v4.3.1
docker push witrocha/chatwit:latest
```

## 🐳 Passo 2: Preparar Configurações

### **2.1 Configurar Variáveis de Ambiente**

Edite o arquivo `.env.production` com suas configurações:

```bash
# Configurações Básicas
FRONTEND_URL=chatwit.seudominio.com
SECRET_KEY_BASE=SUA_SECRET_KEY_BASE_64_CARACTERES_SEGURA

# PostgreSQL
POSTGRES_DATABASE=chatwoot
POSTGRES_USERNAME=chatwoot_prod
POSTGRES_PASSWORD=SUA_SENHA_POSTGRES_SEGURA

# Redis
REDIS_PASSWORD=SUA_SENHA_REDIS_SEGURA

# Email SMTP
MAILER_SENDER_EMAIL=noreply@seudominio.com
SMTP_ADDRESS=smtp.seudominio.com
SMTP_PORT=587
SMTP_USERNAME=seu_usuario_smtp
SMTP_PASSWORD=sua_senha_smtp

# Segurança
FORCE_SSL=true
```

**💡 Gerar SECRET_KEY_BASE:**
```bash
# No Rails console ou online
openssl rand -hex 64
```

## 📦 Passo 3: Deploy no Portainer

### **3.1 Acessar Portainer**
1. Acesse seu Portainer: `https://portainer.seuservidor.com`
2. Navegue para **Stacks** > **Add Stack**

### **3.2 Configurar Stack**

**Nome da Stack:** `chatwit-production`

**Build Method:** `Web editor`

**⚠️ IMPORTANTE:** Use o arquivo atualizado `bkp/chatwitOFICIAL-PRODUCAO-SEM-TELEMETRIA-V4.yaml`

**Diferenças do arquivo v4:**
- ✅ Imagem atualizada: `witrocha/chatwit:v4.3.1`
- ✅ Comando modificado: `bundle exec rails db:chatwit_prepare && bundle exec rails s`
- ✅ Migração automática v3->v4 na inicialização
- ✅ Telemetria completamente desabilitada
- ✅ Configurações de segurança mantidas

**Conteúdo do docker-compose.yml:**
```yaml
# Cole o conteúdo do arquivo bkp/chatwitOFICIAL-PRODUCAO-SEM-TELEMETRIA-V4.yaml aqui
```

### **3.3 Configurar Environment Variables**

No Portainer, na seção **Environment variables**, adicione:

```bash
FRONTEND_URL=chatwit.seudominio.com
SECRET_KEY_BASE=sua_secret_key_base_aqui_pelo_menos_64_caracteres
POSTGRES_DATABASE=chatwoot
POSTGRES_USERNAME=chatwoot_prod
POSTGRES_PASSWORD=sua_senha_postgres_super_segura
REDIS_PASSWORD=sua_senha_redis_super_segura
MAILER_SENDER_EMAIL=noreply@seudominio.com
SMTP_DOMAIN=seudominio.com
SMTP_ADDRESS=smtp.seudominio.com
SMTP_PORT=587
SMTP_USERNAME=seu_usuario_smtp
SMTP_PASSWORD=sua_senha_smtp
SMTP_AUTHENTICATION=login
SMTP_ENABLE_STARTTLS_AUTO=true
SMTP_TLS=false
FORCE_SSL=true
```

### **3.4 Deploy da Stack**
1. Clique em **Deploy the stack**
2. Aguardar download das imagens
3. Verificar logs dos containers

## 🔄 Passo 4: Restaurar Backup (Se Necessário)

### **4.1 Se Tiver Backup do Chatwoot v3**
```bash
# 1. Copiar backup para o container PostgreSQL
docker cp chatwoot_backup.sql.gz container_postgres:/tmp/

# 2. Restaurar backup
docker exec -it container_postgres bash
gunzip -c /tmp/chatwoot_backup.sql.gz | psql -U chatwoot_prod -d chatwoot

# 3. A migração será executada automaticamente na inicialização do Rails
```

### **4.2 Verificar Migração Automática**
```bash
# Verificar logs do container Rails
docker logs chatwit-production_chatwoot_app -f

# A migração v3->v4 é executada automaticamente!
# Logs esperados:
# 🚀 [CHATWIT] Preparando ambiente de produção...
# 🔍 [CHATWIT] Verificando se é migração v3->v4...
# ✅ [CHATWIT] Adicionando colunas necessárias...
# 🚀 [CHATWIT] Executando migrações pendentes...
# ✅ [CHATWIT] Migração v3->v4 concluída com sucesso!
# 🎉 [CHATWIT] Aplicação pronta para uso!
```

### **4.3 Dados Preservados**
A migração automática preserva:
- ✅ Contas de usuário
- ✅ Conversas e mensagens
- ✅ Inboxes e configurações
- ✅ Agentes e equipes
- ✅ Configurações SMTP
- ✅ Integrações

## 🌐 Passo 5: Configurar DNS e SSL

### **5.1 Configurar DNS**
```bash
# Adicionar registro A no seu provedor de DNS
chatwit.seudominio.com A IP_DO_SERVIDOR
```

### **5.2 Configurar SSL (se usando Traefik)**
```yaml
# Já incluído no docker-compose.production.yml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.chatwit.rule=Host(`chatwit.seudominio.com`)"
  - "traefik.http.routers.chatwit.tls=true"
  - "traefik.http.routers.chatwit.tls.certresolver=letsencrypt"
```

### **5.3 Configurar SSL (se usando Nginx Proxy Manager)**
1. Adicionar Proxy Host
2. Domain: `chatwit.seudominio.com`
3. Forward IP: `IP_DO_SERVIDOR`
4. Forward Port: `3000`
5. Ativar SSL/Let's Encrypt

## ✅ Passo 6: Verificação Final

### **6.1 Testar Aplicação**
```bash
# 1. Acessar no navegador
https://chatwit.seudominio.com

# 2. Verificar login
# - Se restaurou backup: use credenciais existentes
# - Se instalação nova: criar conta admin

# 3. Verificar funcionalidades
# - Dashboard carrega
# - Criar inbox
# - Enviar mensagem teste
# - Verificar email
```

### **6.2 Monitorar Logs**
```bash
# No Portainer > Containers > rails > Logs
# Ou via CLI:
docker logs container_rails --tail=100 -f
```

### **6.3 Verificar Performance**
```bash
# No Portainer > Containers > verificar uso de CPU/RAM
# Rails: ~200-500MB RAM
# Sidekiq: ~100-300MB RAM  
# Postgres: ~100-500MB RAM
# Redis: ~10-50MB RAM
```

## 🛠️ Comandos Úteis

### **Gerenciar Stack**
```bash
# Reiniciar stack
# No Portainer: Stack > chatwit-production > Stop/Start

# Atualizar imagem
# 1. Fazer novo build: .\build-producao.ps1 -Version "v4.3.2"
# 2. Push: docker push witrocha/chatwit:v4.3.2
# 3. No Portainer: Stack > Editor > atualizar tag > Redeploy
```

### **Backup/Restore**
```bash
# Backup atual
docker exec container_postgres pg_dump -U chatwoot_prod chatwoot > backup.sql

# Restore
docker exec -i container_postgres psql -U chatwoot_prod chatwoot < backup.sql
```

### **Logs e Debug**
```bash
# Logs em tempo real
docker logs container_rails -f

# Entrar no container
docker exec -it container_rails bash

# Rails console
docker exec -it container_rails bundle exec rails console

# Verificar banco
docker exec -it container_postgres psql -U chatwoot_prod chatwoot
```

## 🔒 Segurança

### **Checklist de Segurança:**
- [ ] SSL/HTTPS configurado
- [ ] Senhas fortes no .env
- [ ] PostgreSQL e Redis não expostos publicamente
- [ ] Firewall configurado (apenas 80, 443, SSH)
- [ ] Backup automático configurado
- [ ] Monitoramento ativo
- [ ] Telemetria desabilitada

## 🎯 Troubleshooting

### **Container Rails não inicia:**
```bash
# Verificar logs
docker logs container_rails

# Problemas comuns:
# - SECRET_KEY_BASE vazia ou muito curta
# - Erro de conexão com PostgreSQL
# - Erro de conexão com Redis
```

### **Erro 500 na aplicação:**
```bash
# Verificar variáveis de ambiente
docker exec container_rails env | grep -E "SECRET_KEY|POSTGRES|REDIS"

# Verificar migração
docker exec container_rails bundle exec rails db:migrate:status
```

### **Email não funciona:**
```bash
# Testar SMTP
docker exec container_rails bundle exec rails console
> ActionMailer::Base.mail(to: "teste@seudominio.com", from: "noreply@seudominio.com", subject: "Teste", body: "Teste").deliver_now
```

---

## 🎉 Sucesso!

Se chegou até aqui, seu **Chatwit v4 Enterprise** está rodando em produção com:

- ✅ **Migração automática** do Chatwoot v3 para v4
- ✅ **Telemetria desabilitada** - 100% privado
- ✅ **SSL/HTTPS** configurado
- ✅ **Enterprise features** ativadas
- ✅ **Backup/Restore** funcional
- ✅ **Deploy via Portainer** simplificado

**🚀 Parabéns pelo deploy!** 🎊 