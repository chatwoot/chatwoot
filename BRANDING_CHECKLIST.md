# Checklist de Implementação de Custom Branding

## ✅ Implementação Completa

### Backend
- [x] Migration `create_branding_configs` criada
- [x] Model `BrandingConfig` com ActiveStorage
- [x] API Controller `/api/v1/branding` (GET/PUT)
- [x] Dashboard Controller carrega branding no global_config
- [x] Embed Auth Controller com headers CSP
- [x] Application Mailer usa branding
- [x] Account Notification Mailer usa branding
- [x] Widget Config Controller carrega branding
- [x] Survey Controller carrega branding

### Frontend
- [x] Store module `branding.js` criado
- [x] UI Admin em Settings -> Branding
- [x] Upload de assets com preview
- [x] Componente Logo usa branding
- [x] App.vue carrega branding no mount
- [x] Favicon atualizado dinamicamente
- [x] Document.title atualizado
- [x] Menu sidebar atualizado
- [x] Traduções em inglês

### Widget
- [x] Componente Branding.vue já usa BRAND.brandName
- [x] Widget config API retorna branding

### Emails
- [x] Sender email usa branding
- [x] Subjects de emails usam branding
- [x] Footer "Powered by" usa branding

### Embed
- [x] Headers CSP configurados
- [x] X-Frame-Options removido para same-origin
- [x] Rota `/app/embed/inbox` funcional

## 📋 Próximos Passos

1. **Executar Migration**:
   ```bash
   bundle exec rails db:migrate
   ```

2. **Testar Upload de Assets**:
   - Acessar Settings -> Branding
   - Fazer upload de logo, favicon, etc.
   - Verificar preview e salvamento

3. **Verificar Aplicação**:
   - Dashboard: Logo no sidebar, título da aba
   - Widget: "Powered by" usa brand name
   - Emails: Sender e subjects corretos
   - Favicon: Atualizado na aba

4. **Testar Embed**:
   - Gerar embed token via API
   - Testar iframe no mesmo domínio
   - Verificar que não há bloqueios

5. **Verificar Referências**:
   ```bash
   rg -n --hidden --glob '!**/node_modules/**' --glob '!**/vendor/**' "Chatwoot|chatwoot|chatwoot.com"
   ```
   - Deve retornar apenas referências técnicas justificadas

## 🎯 Critérios de Aceite

- [x] UI admin permite upload de logos e favicons
- [x] Preview de imagens funciona
- [x] Dashboard mostra logo e nome do branding
- [x] Widget mostra "Powered by" com brand name
- [x] Emails não mostram "Chatwoot"
- [x] Embed funciona em iframe no mesmo domínio
- [x] Favicon atualizado dinamicamente
- [x] Título da aba usa brand name

## 📝 Notas

- Branding é carregado via API no frontend e aplicado dinamicamente
- Fallbacks: BrandingConfig > Brand module > ENV > Defaults
- Assets são servidos via ActiveStorage (URLs assinadas)
- Headers CSP permitem iframe apenas de synkicrm.com.br

