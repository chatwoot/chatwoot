# CommMate Branding Fix

**Data**: 02/11/2025  
**Problema**: Cores aplicadas mas nome e ícones não apareciam  
**Solução**: Correções no Dockerfile.commmate

---

## ❌ **Problemas Identificados**

1. **Diretórios não criados**: `public/brand-assets` não existia antes de copiar
2. **Assets copiados incorretamente**: Nomes de arquivos não correspondiam aos esperados pelo Chatwoot
3. **Entrypoint não funcionava**: CMD com if não executa corretamente
4. **Variáveis de ambiente**: Faltavam no runtime

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

