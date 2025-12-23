# Implementação de Custom Branding White-Label

## Resumo

Sistema completo de Custom Branding white-label para SynkiCRM, com suporte a upload de assets via UI, integração no dashboard/widget/emails, e correção de headers para embed sem bloqueios.

## Arquivos Criados/Modificados

### Backend (Rails)

1. **Migration**: `db/migrate/20251221032529_create_branding_configs.rb`
   - Tabela `branding_configs` com campos: brand_name, brand_website, support_email
   - Criação automática de registro singleton com defaults

2. **Model**: `app/models/branding_config.rb`
   - Singleton pattern (`BrandingConfig.instance`)
   - ActiveStorage attachments: logo_main, logo_compact, favicon, apple_touch_icon
   - Validações de tipo e tamanho de arquivo
   - Métodos helper para URLs dos assets

3. **Controller**: `app/controllers/api/v1/branding_controller.rb`
   - `GET /api/v1/branding` - Retorna configuração atual
   - `PUT /api/v1/branding` - Atualiza textos e arquivos (admin only)

4. **Controllers atualizados**:
   - `app/controllers/dashboard_controller.rb` - Carrega branding no global_config, headers CSP para embed
   - `app/controllers/embed_auth_controller.rb` - Headers CSP para embed
   - `app/mailers/application_mailer.rb` - Usa branding para sender email
   - `app/mailers/administrator_notifications/account_notification_mailer.rb` - Usa branding em subjects

5. **Views atualizadas**:
   - `app/views/layouts/vueapp.html.erb` - Título e favicon dinâmicos

6. **Routes**: `config/routes.rb`
   - Adicionada rota `resource :branding, only: [:show, :update]` em `/api/v1`

### Frontend (Vue.js)

1. **Store Module**: `app/javascript/dashboard/store/modules/branding.js`
   - Estado e actions para carregar branding
   - Atualização automática de favicon e document.title

2. **UI Admin**:
   - `app/javascript/dashboard/routes/dashboard/settings/branding/branding.routes.js`
   - `app/javascript/dashboard/routes/dashboard/settings/branding/Index.vue`
   - `app/javascript/dashboard/api/branding.js`

3. **Componentes atualizados**:
   - `app/javascript/dashboard/components-next/icon/Logo.vue` - Usa branding.logoCompactUrl
   - `app/javascript/dashboard/App.vue` - Carrega branding no mount
   - `app/javascript/dashboard/components-next/sidebar/Sidebar.vue` - Menu "Branding"

4. **Traduções**: `app/javascript/dashboard/i18n/locale/en/branding.json`

5. **Store**: `app/javascript/dashboard/store/index.js` - Adicionado módulo branding

## Funcionalidades

### 1. Upload de Assets via UI
- **Localização**: Settings -> Branding (menu sidebar)
- **Uploads suportados**:
  - Logo Principal (PNG/JPG/SVG/GIF/WebP, max 2MB)
  - Logo Compacto (PNG/JPG/SVG/GIF/WebP, max 2MB)
  - Favicon (PNG/ICO/SVG, max 1MB)
  - Apple Touch Icon (PNG/JPG, max 1MB)
- **Preview**: Imagens mostram preview antes de salvar
- **Atualização imediata**: Após salvar, UI atualiza sem rebuild

### 2. Integração no Dashboard
- Logo no sidebar usa `branding.logoCompactUrl` ou `branding.logoMainUrl`
- Título da página (`document.title`) usa `branding.brandName`
- Favicon atualizado dinamicamente via JavaScript

### 3. Integração no Widget
- Componente `Branding.vue` já usa `BRAND.brandName` (já implementado anteriormente)
- "Powered by" usa brand name do branding

### 4. Integração em Emails
- Sender email usa `branding.brand_name` e `branding.support_email`
- Subjects de emails usam brand name dinâmico
- Footer "Powered by" usa `global_config['BRAND_NAME']`

### 5. Embed sem Bloqueios
- Headers CSP configurados para permitir iframe de `synkicrm.com.br`
- `X-Frame-Options` removido para permitir same-origin embedding
- Rota `/app/embed/inbox` funciona em iframe no mesmo domínio

## Como Usar

### 1. Acessar Configurações de Branding
1. Faça login como administrador
2. Vá em **Settings** (menu lateral) -> **Branding**
3. Preencha os campos de texto:
   - Brand Name (ex: "SynkiCRM")
   - Brand Website (ex: "https://synkicrm.com.br/")
   - Support Email (ex: "suporte@synkicrm.com.br")

### 2. Fazer Upload de Assets
1. Na mesma tela, clique em **"Choose File"** para cada asset desejado
2. Selecione o arquivo (validação automática de tipo e tamanho)
3. Preview será exibido automaticamente
4. Clique em **"Save Changes"**
5. Assets serão aplicados imediatamente

### 3. Verificar Aplicação
- **Dashboard**: Logo no sidebar, título da aba
- **Widget**: "Powered by" usa brand name
- **Emails**: Sender e subjects usam brand name
- **Favicon**: Atualizado automaticamente na aba do navegador

### 4. Embed em iframe
```html
<iframe 
  src="https://chat.synkicrm.com.br/app/embed/inbox?inbox_id=123" 
  width="100%" 
  height="800px"
  frameborder="0">
</iframe>
```

## Validações

- **Tipos de arquivo**: Validados no backend
- **Tamanho máximo**: Logo (2MB), Favicon (1MB)
- **Formato de email**: Validado com regex
- **Formato de URL**: Validado com URI parser

## Fallbacks

Se `BrandingConfig` não estiver disponível, o sistema usa:
1. `Brand` module (se definido)
2. Variáveis de ambiente (`BRAND_NAME`, `BRAND_WEBSITE`, `BRAND_SUPPORT_EMAIL`)
3. Defaults hardcoded ("SynkiCRM", "https://synkicrm.com.br/", "suporte@synkicrm.com.br")

## Headers CSP para Embed

- **Permitido**: `'self'`, `https://synkicrm.com.br`, `https://*.synkicrm.com.br`
- **X-Frame-Options**: Removido para permitir same-origin
- **Aplicado em**: `/app/embed/*` e `/embed/auth`

## Próximos Passos

1. Executar migration: `bundle exec rails db:migrate`
2. Testar upload de assets na UI
3. Verificar aplicação em dashboard/widget/emails
4. Testar embed em iframe no mesmo domínio

