# 🚀 Deploy FassZap no EasyPanel

Este guia mostra como fazer deploy do FassZap no EasyPanel de forma simples e rápida.

## 📋 **Pré-requisitos**

- Conta no EasyPanel
- Domínio configurado (opcional)
- API keys para Fabiana AI (opcional)

## 🎯 **Método 1: Deploy Automático (Recomendado)**

### **1. Upload do ZIP**
1. Faça upload do arquivo `fasszap-easypanel.zip` no EasyPanel
2. Extraia o conteúdo no seu projeto
3. O EasyPanel detectará automaticamente o `docker-compose.easypanel.yml`

### **2. Configuração Automática**
O EasyPanel criará automaticamente:
- ✅ **fasszap-app** - Aplicação principal
- ✅ **fasszap-sidekiq** - Worker de background
- ✅ **fasszap-db** - Banco PostgreSQL
- ✅ **fasszap-redis** - Cache Redis

### **3. Variáveis de Ambiente**
Configure estas variáveis no EasyPanel:

#### **🔧 Obrigatórias**
```bash
SECRET_KEY_BASE=cb26527b7f0b99738ed6ac1a65992340
FRONTEND_URL=https://seu-dominio.com
POSTGRES_PASSWORD=sua_senha_segura
REDIS_PASSWORD=sua_senha_redis
```

#### **🤖 Fabiana AI (Opcional)**
```bash
# OpenAI
FABIANA_OPEN_AI_API_KEY=sk-...
FABIANA_OPEN_AI_MODEL=gpt-4o-mini

# ChatGPT
FABIANA_CHATGPT_API_KEY=sk-...
FABIANA_CHATGPT_MODEL=gpt-4

# Groq
FABIANA_GROQ_API_KEY=gsk_...
FABIANA_GROQ_MODEL=llama3-8b-8192

# Provedor ativo
FABIANA_AI_PROVIDER=openai
```

## 🎯 **Método 2: Deploy Manual**

### **1. Criar Projeto**
1. No EasyPanel, clique em "New Project"
2. Nome: `fasszap`
3. Selecione "Docker Compose"

### **2. Configurar Services**

#### **App Principal**
```yaml
fasszap:
  image: chatwoot/chatwoot:latest
  ports:
    - "3000:3000"
  environment:
    CW_EDITION: enterprise
    INSTALLATION_PRICING_PLAN: enterprise
    FRONTEND_URL: https://seu-dominio.com
    # ... outras variáveis
```

#### **Database**
```yaml
db:
  image: postgres:13-alpine
  environment:
    POSTGRES_DB: fasszap_production
    POSTGRES_USER: postgres
    POSTGRES_PASSWORD: sua_senha
```

#### **Redis**
```yaml
redis:
  image: redis:7-alpine
  command: redis-server --requirepass sua_senha_redis
```

## 🔧 **Configuração Pós-Deploy**

### **1. Primeiro Acesso**
1. Aguarde 2-3 minutos para inicialização
2. Acesse: `https://seu-dominio.com`
3. Crie sua conta de administrador

### **2. Verificar FassZap**
1. Vá em Settings > General
2. Verifique se aparece "FassZap" no nome
3. Confirme que o plano é "Enterprise"

### **3. Configurar Fabiana AI**
1. Vá em Settings > Fabiana AI
2. Configure suas API keys
3. Teste a conectividade
4. Escolha o provedor preferido

## 🔍 **Verificação e Testes**

### **Logs do Container**
```bash
# Ver logs da aplicação
docker logs fasszap_fasszap_1

# Ver logs do Sidekiq
docker logs fasszap_fasszap-sidekiq_1
```

### **Health Checks**
- **App**: `https://seu-dominio.com/api/v1/accounts`
- **Database**: Conectividade automática
- **Redis**: Cache funcionando

### **Teste da Fabiana AI**
1. Crie um inbox
2. Configure a Fabiana AI
3. Envie uma mensagem de teste
4. Verifique se a IA responde

## 🛠️ **Solução de Problemas**

### **App não inicia**
```bash
# Verificar variáveis de ambiente
echo $SECRET_KEY_BASE
echo $FRONTEND_URL

# Verificar conectividade do banco
pg_isready -h fasszap-db -U postgres
```

### **Fabiana AI não funciona**
```bash
# Verificar API keys
echo $FABIANA_OPEN_AI_API_KEY

# Testar conectividade
curl -X POST /api/v1/accounts/1/fabiana/settings/test
```

### **Notificações não funcionam**
```bash
# Verificar configurações
echo $CHATWOOT_HUB_URL
echo $DISABLE_TELEMETRY
```

## 📊 **Monitoramento**

### **Métricas Importantes**
- **CPU**: < 80% em uso normal
- **RAM**: ~1-2GB por container
- **Disk**: Crescimento gradual do storage
- **Network**: Tráfego HTTP/HTTPS

### **Logs para Monitorar**
- Erros de conexão com banco
- Falhas de API da Fabiana AI
- Problemas de notificação push

## 🔄 **Atualizações**

### **Atualizar FassZap**
1. Baixe nova versão do ZIP
2. Substitua arquivos no EasyPanel
3. Rebuild dos containers
4. Execute `./bin/fasszap_setup` se necessário

### **Backup**
- **Database**: Backup automático do PostgreSQL
- **Storage**: Backup dos volumes persistentes
- **Config**: Export das variáveis de ambiente

## 🎉 **Resultado Final**

Após o deploy você terá:
- ✅ **FassZap funcionando** com tema laranja
- ✅ **Enterprise ativado** gratuitamente
- ✅ **Fabiana AI** com múltiplos provedores
- ✅ **Notificações push** funcionando
- ✅ **Branding personalizado** (sem "Powered by Chatwoot")

---

**🧡 FassZap está pronto para uso no EasyPanel! 🚀**
