# 📦 FassZap EasyPanel Package

## 🎉 **Pacote Criado com Sucesso!**

O arquivo `fasszap-easypanel.zip` (42KB) está pronto para deploy no EasyPanel.

---

## 📋 **Conteúdo do Pacote**

### **🔧 Arquivos de Configuração**
- `config/installation_config.yml` - Configurações principais do FassZap
- `config/initializers/fasszap_enterprise.rb` - Inicializador enterprise
- `enterprise/config/premium_features.yml` - Funcionalidades premium
- `.env.example` - Exemplo de variáveis de ambiente

### **🤖 Fabiana AI**
- `enterprise/app/services/fabiana/` - Serviços da Fabiana AI
  - `ai_service_factory.rb` - Factory para múltiplos provedores
  - `openai_service.rb` - Integração OpenAI
  - `chatgpt_service.rb` - Integração ChatGPT
  - `groq_service.rb` - Integração Groq
- `enterprise/app/controllers/api/v1/accounts/fabiana/` - API da Fabiana

### **🎨 Tema Laranja**
- `app/assets/stylesheets/` - Estilos modificados
- `theme/colors.js` - Cores do tema
- `public/manifest.json` - Manifest PWA atualizado

### **🐳 Docker & Deploy**
- `Dockerfile` - Dockerfile otimizado
- `docker-compose.yml` - Configuração para EasyPanel
- `easypanel.yml` - Configuração específica EasyPanel
- `start.sh` - Script de inicialização

### **📚 Documentação**
- `README_FASSZAP.md` - Documentação completa
- `DEPLOY_EASYPANEL.md` - Guia de deploy
- `QUICK_START.md` - Início rápido

### **🛠️ Scripts**
- `bin/fasszap_setup` - Script de configuração
- `bin/fasszap_test` - Script de validação
- `db/migrate/20241212000001_enable_fasszap_enterprise.rb` - Migration

---

## 🚀 **Como Usar no EasyPanel**

### **1. Upload do Pacote**
1. Acesse seu EasyPanel
2. Crie novo projeto: "FassZap"
3. Faça upload do `fasszap-easypanel.zip`
4. Extraia o conteúdo

### **2. Deploy Automático**
O EasyPanel detectará automaticamente:
- ✅ `docker-compose.yml` - Configuração dos serviços
- ✅ `Dockerfile` - Build da aplicação
- ✅ Volumes e networks necessários

### **3. Configuração Mínima**
Configure apenas estas variáveis obrigatórias:
```bash
SECRET_KEY_BASE=cb26527b7f0b99738ed6ac1a65992340
FRONTEND_URL=https://seu-dominio.com
POSTGRES_PASSWORD=sua_senha_segura_123
REDIS_PASSWORD=sua_senha_redis_123
```

### **4. Configuração Opcional - Fabiana AI**
Para ativar a IA, adicione uma ou mais:
```bash
# OpenAI
FABIANA_OPEN_AI_API_KEY=sk-...
FABIANA_AI_PROVIDER=openai

# Groq (mais rápido)
FABIANA_GROQ_API_KEY=gsk_...
FABIANA_AI_PROVIDER=groq

# ChatGPT
FABIANA_CHATGPT_API_KEY=sk-...
FABIANA_AI_PROVIDER=chatgpt
```

---

## ⚡ **Deploy em 3 Passos**

### **Passo 1: Upload**
- Upload do ZIP no EasyPanel
- Extrair arquivos

### **Passo 2: Configurar**
- Definir `FRONTEND_URL`
- Definir senhas seguras
- (Opcional) Configurar API keys da IA

### **Passo 3: Deploy**
- Clicar em "Deploy"
- Aguardar 2-3 minutos
- Acessar sua instância FassZap

---

## 🎯 **Resultado Final**

Após o deploy você terá:

### **✅ FassZap Completo**
- Interface com tema laranja
- Branding "FassZap" (sem Chatwoot)
- Enterprise ativado gratuitamente
- Todas as funcionalidades premium

### **🤖 Fabiana AI**
- Suporte a 3 provedores (OpenAI, ChatGPT, Groq)
- Troca dinâmica de provedor
- Interface de configuração
- Fallback automático

### **📱 Funcionalidades**
- Notificações push (mobile/web)
- Audit logs
- SLA management
- Custom roles
- Disable branding

### **🔧 Infraestrutura**
- PostgreSQL 13
- Redis 7
- Sidekiq workers
- Health checks
- Auto-scaling ready

---

## 🆘 **Suporte**

### **Logs e Debug**
```bash
# Ver logs da aplicação
docker logs fasszap_fasszap_1

# Testar configuração
./bin/fasszap_test

# Reconfigurar se necessário
./bin/fasszap_setup
```

### **Problemas Comuns**
1. **App não inicia**: Verificar `SECRET_KEY_BASE` e `FRONTEND_URL`
2. **Banco não conecta**: Verificar `POSTGRES_PASSWORD`
3. **IA não funciona**: Verificar API keys da Fabiana
4. **Tema não aplica**: Aguardar build completo dos assets

### **Health Checks**
- **App**: `https://seu-dominio.com/api/v1/accounts`
- **Database**: Conectividade automática
- **Redis**: Cache funcionando
- **Fabiana**: `POST /api/v1/accounts/1/fabiana/settings/test`

---

## 📊 **Especificações Técnicas**

### **Recursos Mínimos**
- **CPU**: 1 vCPU
- **RAM**: 2GB
- **Storage**: 10GB
- **Network**: 1Gbps

### **Recursos Recomendados**
- **CPU**: 2 vCPU
- **RAM**: 4GB
- **Storage**: 50GB
- **Network**: 1Gbps

### **Escalabilidade**
- Horizontal scaling via EasyPanel
- Load balancer ready
- Database clustering support
- Redis clustering support

---

## 🎉 **Pronto para Produção!**

O pacote `fasszap-easypanel.zip` contém tudo necessário para um deploy completo e funcional do FassZap no EasyPanel.

**🧡 FassZap - Enterprise Customer Support Platform with Fabiana AI 🤖**
