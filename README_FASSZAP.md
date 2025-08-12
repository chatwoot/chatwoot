# 🧡 FassZap - Enterprise Customer Support Platform

FassZap é um fork do Chatwoot focado em privacidade e funcionalidades enterprise gratuitas.

## 🌟 Principais Diferenças do Chatwoot

### ✅ **Funcionalidades Incluídas**
- ✅ **Enterprise Plan Gratuito** - Todas as funcionalidades premium ativadas
- ✅ **Notificações Push** - Mobile e web funcionando via hub oficial
- ✅ **Branding Personalizado** - Removido "Powered by Chatwoot"
- ✅ **Audit Logs** - Logs de auditoria completos
- ✅ **SLA Management** - Gerenciamento de SLA
- ✅ **Custom Roles** - Funções personalizadas
- ✅ **Tema Laranja** - Interface com cores laranja ao invés de azul
- ✅ **Fabiana AI** - IA integrada com múltiplos provedores (OpenAI, ChatGPT, Groq)

### 🚫 **Funcionalidades Removidas/Modificadas**
- 🚫 **Telemetria Reduzida** - Apenas dados essenciais para notificações
- 🚫 **Sem Sync com Hub** - Não envia métricas ou dados de uso
- 🚫 **Sem Billing** - Sistema de cobrança removido
- 🔄 **Captain → Fabiana** - IA renomeada e expandida com múltiplos provedores

## 🚀 Instalação e Configuração

### 1. **Configuração Inicial**

Após instalar o FassZap, execute o script de configuração:

```bash
# Executar setup do FassZap
./bin/fasszap_setup

# Ou via Rails
bundle exec rails runner ./bin/fasszap_setup
```

### 2. **Variáveis de Ambiente Necessárias**

```bash
# Configurações básicas
SECRET_KEY_BASE=sua_chave_secreta
FRONTEND_URL=https://seu-dominio.com
DEFAULT_LOCALE=pt_BR

# Enterprise sempre ativo
CW_EDITION=enterprise
INSTALLATION_PRICING_PLAN=enterprise
INSTALLATION_PRICING_PLAN_QUANTITY=10

# Notificações (manter para funcionar)
CHATWOOT_HUB_URL=https://hub.2.chatwoot.com
DISABLE_TELEMETRY=false

# Database
POSTGRES_DATABASE=fasszap_production
POSTGRES_HOST=localhost
POSTGRES_USERNAME=postgres
POSTGRES_PASSWORD=sua_senha

# Redis
REDIS_URL=redis://localhost:6379
```

### 3. **Executar Migração**

```bash
# Aplicar configurações do FassZap
bundle exec rails db:migrate

# Preparar banco (se necessário)
bundle exec rails db:chatwoot_prepare
```

## 🔧 Configurações Específicas do FassZap

### **Cores Personalizadas**
- **Cor Principal**: `#ff7b1f` (laranja)
- **Cor Secundária**: `#5d7592`
- **Backgrounds**: Tons suaves de laranja

### **Branding**
- **Nome**: FassZap
- **URLs**: https://www.fasszap.com
- **Logos**: `/brand-assets/fasszap_*`

### **Funcionalidades Enterprise Ativas**
- `disable_branding` - Sem marca "Powered by"
- `audit_logs` - Logs de auditoria
- `sla` - Gerenciamento de SLA
- `fabiana_integration` - IA Fabiana integrada
- `custom_roles` - Funções personalizadas

## 🤖 Fabiana AI

A Fabiana é a IA integrada do FassZap, sucessora do Captain, com suporte a múltiplos provedores:

### **Provedores Suportados**
- **OpenAI** - GPT-4, GPT-4o, GPT-3.5-turbo
- **ChatGPT** - Modelos otimizados para conversação
- **Groq** - LLaMA 3, Mixtral (alta velocidade)

### **Configuração da Fabiana**
```bash
# Definir provedor padrão
FABIANA_AI_PROVIDER=openai

# OpenAI
FABIANA_OPEN_AI_API_KEY=sua_chave_openai
FABIANA_OPEN_AI_MODEL=gpt-4o-mini

# ChatGPT
FABIANA_CHATGPT_API_KEY=sua_chave_chatgpt
FABIANA_CHATGPT_MODEL=gpt-4

# Groq
FABIANA_GROQ_API_KEY=sua_chave_groq
FABIANA_GROQ_MODEL=llama3-8b-8192
```

### **Funcionalidades**
- ✅ **Múltiplos Provedores** - Escolha entre OpenAI, ChatGPT e Groq
- ✅ **Troca Dinâmica** - Altere o provedor sem reiniciar
- ✅ **Fallback Automático** - Se um provedor falhar, tenta outro
- ✅ **Otimizações Específicas** - Cada provedor tem configurações otimizadas

## 📱 Notificações

As notificações funcionam normalmente através do hub oficial do Chatwoot:
- **Mobile**: Via FCM através do hub
- **Web**: Via VAPID keys locais
- **Dados enviados**: Apenas necessários para notificações

## 🔄 Atualizações e Manutenção

### **Após Reinicialização**
Execute novamente o setup se necessário:
```bash
./bin/fasszap_setup
```

### **Verificar Status**
```bash
# Via Rails console
bundle exec rails console

# Verificar plano
ChatwootHub.pricing_plan
# => "enterprise"

# Verificar funcionalidades de uma conta
Account.first.enabled_features
```

## 🆘 Solução de Problemas

### **Enterprise não ativado**
```bash
# Forçar ativação
./bin/fasszap_setup
```

### **Notificações não funcionam**
Verificar variáveis:
```bash
CHATWOOT_HUB_URL=https://hub.2.chatwoot.com
DISABLE_TELEMETRY=false
```

### **Cores não aplicadas**
```bash
# Recompilar assets
bundle exec rails assets:precompile
```

## 📄 Licença

Este projeto mantém a licença original do Chatwoot com as modificações específicas do FassZap.

---

**FassZap** - Customer Support Platform with Privacy Focus 🧡
