# CommMate Branding Fix

**Last Updated**: 09/11/2025  
**Status**: ✅ Fully Resolved

---

## 🔍 **Root Cause Discovered (November 2025)**

### **The ConfigLoader Problem**

Chatwoot has a task that runs **AFTER EVERY migration**:

```ruby
# lib/tasks/db_enhancements.rake
Rake::Task['db:migrate'].enhance do
  ConfigLoader.new.process  # Loads config/installation_config.yml
end
```

**What was happening:**
1. Migration runs → ConfigLoader.process executes
2. ConfigLoader reads `config/installation_config.yml`
3. If any branding config missing, creates it with **"Chatwoot"** defaults
4. **CommMate branding gets overwritten!**

This is why branding kept reverting after container restarts or migrations.

---

## ✅ **Complete Solution (Multiple Layers)**

### **Layer 1: Initializer Override (Primary Fix)**

**File:** `custom/config/initializers/commmate_config_overrides.rb`

Runs AFTER ConfigLoader and intelligently overrides configs:

```ruby
# Only overrides if value is still Chatwoot default
if existing.value == 'Chatwoot'
  existing.update!(value: 'CommMate')
end
```

**Benefits:**
- Runs on every Rails startup
- Only overrides Chatwoot defaults
- Preserves user customizations
- Automatic and bulletproof

### **Layer 2: CommMate Config Defaults**

**File:** `custom/config/installation_config.yml`

Contains CommMate-specific defaults for branding configs:
- INSTALLATION_NAME: CommMate
- BRAND_NAME: CommMate
- LOGO paths: /brand-assets/logo-full.png
- URLs: commmate.com
- DEFAULT_LOCALE: pt_BR

### **Layer 3: Migration (One-Time)**

**File:** `db/migrate/20251102174650_apply_commmate_branding.rb`

Applies branding once during migrations (backup redundancy).

### **Layer 4: Docker ENV Defaults**

**File:** `docker/Dockerfile.commmate`

```dockerfile
ENV APP_NAME="CommMate" \
    BRAND_NAME="CommMate" \
    INSTALLATION_NAME="CommMate" \
    BRAND_URL="https://commmate.com" \
    HIDE_BRANDING="true" \
    DEFAULT_LOCALE="pt_BR" \
    ENABLE_ACCOUNT_SIGNUP="false" \
    DISABLE_CHATWOOT_CONNECTIONS="true" \
    DISABLE_TELEMETRY="true" \
    MAILER_SENDER_EMAIL="CommMate <support@commmate.com>"
```

All settings built into image, overridable via docker-compose.

---

## ❌ **Historical Problems (Pre-November 2025)**

1. **Diretórios não criados**: `public/brand-assets` não existia antes de copiar
2. **Assets copiados incorretamente**: Nomes de arquivos não correspondiam aos esperados pelo Chatwoot
3. **Entrypoint não funcionava**: CMD com if não executa corretamente
4. **Variáveis de ambiente**: Faltavam no runtime
5. **ConfigLoader reverting branding**: Discovered November 2025 ⚠️

---

## ✅ **Correções Aplicadas**

### 1. Diretórios Criados Corretamente
```dockerfile
RUN mkdir -p /app/public/images \
             /app/public/brand-assets \
             /app/config/commmate \
             /app/custom/config
```

### 2. Assets com Nomes Corretos
```dockerfile
# Logos com nomes que o Chatwoot espera
COPY custom/assets/logos/logo-full.png /app/public/brand-assets/logo.png
COPY custom/assets/logos/logo-full-dark.png /app/public/brand-assets/logo_dark.png
COPY custom/assets/logos/logo-icon.png /app/public/brand-assets/logo_thumbnail.png
```

### 3. Entrypoint Wrapper
```dockerfile
# Cria um wrapper script que escolhe o entrypoint correto
RUN echo '#!/bin/sh' > /docker-entrypoint-wrapper.sh && \
    echo 'if [ -f /app/custom/config/docker-entrypoint.sh ]; then' >> /docker-entrypoint-wrapper.sh && \
    echo '  exec /app/custom/config/docker-entrypoint.sh' >> /docker-entrypoint-wrapper.sh && \
    echo 'else' >> /docker-entrypoint-wrapper.sh && \
    echo '  exec docker/entrypoints/rails.sh "$@"' >> /docker-entrypoint-wrapper.sh && \
    echo 'fi' >> /docker-entrypoint-wrapper.sh
```

### 4. ENV Vars Mantidas
```dockerfile
ENV APP_NAME="CommMate" \
    BRAND_NAME="CommMate" \
    INSTALLATION_NAME="CommMate" \
    BRAND_URL="https://commmate.com"
```

---

## 📋 **Arquivos de Assets**

### Logos
- `logo-full.png` → `/app/public/brand-assets/logo.png`
- `logo-full-dark.png` → `/app/public/brand-assets/logo_dark.png`
- `logo-icon.png` → `/app/public/brand-assets/logo_thumbnail.png`

### Favicons
- `favicon.ico`
- `favicon-16x16.png`
- `favicon-32x32.png`
- `android-chrome-192x192.png`
- `android-chrome-512x512.png`
- `apple-touch-icon.png`

---

## 🔄 **Como Rebuildar**

```bash
# Limpar imagens antigas
podman rmi -f commmate/commmate:v4.7.0 commmate/commmate:latest
podman manifest rm commmate/commmate:v4.7.0 2>/dev/null || true

# Rebuild multi-plataforma
cd /Users/schimuneck/projects/commmmate/chatwoot
./custom/script/build_multiplatform.sh v4.7.1

# Push para Docker Hub
podman manifest push commmate/commmate:v4.7.1 docker://commmate/commmate:v4.7.1
podman manifest push commmate/commmate:v4.7.1 docker://commmate/commmate:latest

# Deploy em produção
ssh root@200.98.72.137 "cd /opt/evolution-chatwoot && \
  docker compose stop chatwoot sidekiq && \
  docker pull commmate/commmate:latest && \
  docker compose up -d chatwoot sidekiq"
```

---

## ✅ **Resultado Esperado**

Após rebuild e deploy:
- ✅ Logo CommMate aparece no header
- ✅ Logo CommMate aparece no login
- ✅ Favicon CommMate na aba do navegador
- ✅ Nome "CommMate" no título da página
- ✅ Cores verdes aplicadas (#107e44)
- ✅ Ícones CommMate em todos os lugares

---

## 🔍 **Verificar se Funcionou**

1. Abrir https://crm.commmate.com
2. Verificar título da aba: deve ser "CommMate"
3. Verificar favicon: deve ser o logo CommMate
4. Fazer login e verificar logo no header
5. Verificar cores verdes nas interfaces

---

**Status**: Correções aplicadas, pronto para rebuild

