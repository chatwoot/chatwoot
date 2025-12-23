# Resumo das Mudanças de Branding - SynkiCRM

## 📋 Visão Geral

Este documento resume todas as mudanças realizadas para fazer o white-label completo do Chatwoot para SynkiCRM.

## ✅ Mudanças Implementadas

### 1. Módulo Central de Branding (Frontend)

**Arquivo:** `app/javascript/shared/brand.js`
- Criado módulo central que exporta constantes de branding
- Valores padrão: SynkiCRM, https://synkicrm.com.br/, suporte@synkicrm.com.br
- Pode ser sobrescrito via `window.globalConfig` (backend)

**Uso:**
```javascript
import BRAND from 'shared/brand';
// ou
import { BRAND_NAME, PRODUCT_NAME } from 'shared/brand';
```

### 2. Initializer Backend (Rails)

**Arquivo:** `config/initializers/brand.rb`
- Módulo `Brand` com constantes centralizadas
- Lê de variáveis de ambiente com defaults para SynkiCRM
- Helper `Brand.replace_brand_name(text)` para substituir referências

**Variáveis de Ambiente:**
- `BRAND_NAME` (default: SynkiCRM)
- `BRAND_WEBSITE` (default: https://synkicrm.com.br/)
- `BRAND_SUPPORT_EMAIL` (default: suporte@synkicrm.com.br)
- `BRAND_LEGAL_NAME` (default: SynkiCRM)
- `BRAND_DOMAIN` (default: synkicrm.com.br)

### 3. Sistema de Temas CSS

**Arquivo:** `app/javascript/dashboard/assets/scss/_themes.scss`
- Definido tema `theme-synkicrm` com CSS variables
- Variáveis para cores, espaçamentos, tipografia
- Suporte a dark mode
- Aplicado automaticamente no `body` via `App.vue`

**Variáveis principais:**
- `--brand-primary`: #1f93ff
- `--brand-accent`: #00d4aa
- `--bg-sidebar`, `--text-sidebar`
- `--bg-surface`, `--text-default`
- E muitas outras...

### 4. Arquivos de Configuração Atualizados

**`config/installation_config.yml`:**
- `INSTALLATION_NAME`: 'SynkiCRM'
- `BRAND_URL`: 'https://synkicrm.com.br/'
- `WIDGET_BRAND_URL`: 'https://synkicrm.com.br/'
- `BRAND_NAME`: 'SynkiCRM'

### 5. Internacionalização (i18n)

**Arquivos atualizados:**
- `app/javascript/widget/i18n/locale/en.json`: `POWERED_BY` agora usa placeholder `%{brand}`
- `app/javascript/dashboard/i18n/locale/en/inboxMgmt.json`: `BRANDING_TEXT` usa placeholder

**Componente Branding.vue:**
- Atualizado para usar `$t('POWERED_BY', { brand: globalConfig.brandName })`
- Usa módulo `shared/brand.js` como fallback

### 6. Mailers (Backend)

**Arquivos atualizados:**
- `app/mailers/application_mailer.rb`: `default from` usa `Brand::BRAND_NAME` e `Brand::SUPPORT_EMAIL`
- `app/mailers/conversation_reply_mailer.rb`: Atualizado para usar Brand module

**Template de email:**
- `app/views/layouts/mailer/base.liquid`: Já usa `global_config['BRAND_NAME']` e `global_config['BRAND_URL']`

### 7. Composable de Branding

**Arquivo:** `app/javascript/shared/composables/useBranding.js`
- Atualizado para usar módulo `shared/brand.js`
- Método `replaceInstallationName()` substitui "Chatwoot" por brand name
- Novo método `getBrandName()` retorna brand name atual

### 8. Layouts e Templates

**`app/views/layouts/vueapp.html.erb`:**
- Título usa `@global_config['INSTALLATION_NAME']` (já estava correto)
- Classe `theme-synkicrm` aplicada no `<body>`

**`app/javascript/dashboard/App.vue`:**
- Método `applyBrandTheme()` adicionado
- Aplica classe de tema no mount

### 9. Store GlobalConfig

**`app/javascript/shared/store/globalConfig.js`:**
- Getters atualizados:
  - `isACustomBrandedInstance`: Agora verifica contra 'SynkiCRM' (default)
  - `isAChatwootInstance`: Agora verifica contra 'SynkiCRM' (legacy)

## 🔧 Como Personalizar

### Via Variáveis de Ambiente (Backend)

Adicione ao arquivo `.env`:

```bash
# Branding
BRAND_NAME="SynkiCRM"
BRAND_WEBSITE="https://synkicrm.com.br/"
BRAND_SUPPORT_EMAIL="suporte@synkicrm.com.br"
BRAND_LEGAL_NAME="SynkiCRM"
BRAND_DOMAIN="synkicrm.com.br"

# Tema (opcional)
THEME_NAME="synkicrm"
```

### Via Installation Config (Dashboard)

As configurações podem ser alteradas via dashboard em:
- Settings → Installation → Branding

### Logos e Favicons

Substitua os arquivos em `public/brand-assets/`:
- `logo.svg`
- `logo_dark.svg`
- `logo_thumbnail.svg`

Ou atualize os caminhos em `config/installation_config.yml`.

## 📝 Arquivos Modificados

### Frontend
1. `app/javascript/shared/brand.js` (NOVO)
2. `app/javascript/shared/composables/useBranding.js`
3. `app/javascript/shared/components/Branding.vue`
4. `app/javascript/shared/store/globalConfig.js`
5. `app/javascript/dashboard/App.vue`
6. `app/javascript/dashboard/assets/scss/_themes.scss` (NOVO)
7. `app/javascript/dashboard/assets/scss/app.scss`
8. `app/javascript/widget/i18n/locale/en.json`
9. `app/javascript/dashboard/i18n/locale/en/inboxMgmt.json`

### Backend
1. `config/initializers/brand.rb` (NOVO)
2. `config/installation_config.yml`
3. `app/mailers/application_mailer.rb`
4. `app/mailers/conversation_reply_mailer.rb`
5. `app/views/layouts/vueapp.html.erb`

## ✅ Script de Verificação

Execute para verificar se há referências a Chatwoot:

```bash
bash scripts/check_branding.sh
```

O script verifica:
- Arquivos frontend (app/javascript)
- Views (app/views)
- Configurações (config)
- Mailers (app/mailers)

E exclui:
- node_modules, vendor, .git
- Arquivos de teste (spec, test)
- Comentários técnicos

## 🚀 Próximos Passos

1. **Substituir Logos**: Coloque os logos do SynkiCRM em `public/brand-assets/`
2. **Favicons**: Substitua favicons em `public/` (favicon-*.png, apple-icon-*.png, etc.)
3. **Testar**: Execute o script de verificação e teste todas as funcionalidades
4. **i18n Completo**: Atualize outros idiomas se necessário (focamos em `en` por enquanto)

## 📌 Notas Importantes

- As mudanças são centralizadas e fáceis de manter
- Compatível com sincronização upstream (usando placeholders e ENV)
- Não remove funcionalidades, apenas troca branding
- Sistema de temas permite customização visual futura

## 🔍 Verificação Manual

Para verificar manualmente:

```bash
# Buscar referências a Chatwoot (excluindo node_modules, vendor, .git)
grep -r "Chatwoot\|chatwoot" app/javascript app/views config app/mailers \
  --exclude-dir=node_modules --exclude-dir=vendor --exclude-dir=.git \
  | grep -v "useBranding\|replaceInstallationName\|Brand\.\|BRAND_\|#.*Chatwoot\|//.*Chatwoot"
```

