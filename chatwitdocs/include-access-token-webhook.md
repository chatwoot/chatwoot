# Feature: Include Access Token in Webhook Payload

**Data:** 2026-02-03
**Status:** Implementado

## Descrição

Adicionada a funcionalidade de incluir o ACCESS_TOKEN do administrador da conta no payload dos webhooks. Esta feature é especialmente útil para integração com o SocialWise, permitindo que o webhook receba autenticação para fazer chamadas de volta à API do Chatwit.

## Arquivos Modificados/Criados

### Backend

1. **Migration** - `db/migrate/20260203000001_add_include_access_token_to_webhooks.rb`
   - Adiciona coluna `include_access_token` (boolean, default: false) na tabela webhooks

2. **Controller** - `app/controllers/api/v1/accounts/webhooks_controller.rb`
   - Adicionado `:include_access_token` nos parâmetros permitidos

3. **Listener** - `app/listeners/webhook_listener.rb`
   - Modificado `deliver_account_webhooks` para incluir `ACCESS_TOKEN` no payload quando habilitado
   - O token é obtido do primeiro administrador da conta (`account.administrators.first.access_token.token`)

### Frontend

4. **Vue Component** - `app/javascript/dashboard/routes/dashboard/settings/integrations/Webhooks/WebhookForm.vue`
   - Adicionado checkbox para habilitar/desabilitar inclusão do access token
   - Estilizado com classes Tailwind para consistência visual

5. **i18n** - `app/javascript/dashboard/i18n/locale/en/integrations.json`
   - Adicionadas traduções para o novo campo:
     - `INTEGRATION_SETTINGS.WEBHOOK.FORM.ACCESS_TOKEN.LABEL`
     - `INTEGRATION_SETTINGS.WEBHOOK.FORM.ACCESS_TOKEN.HELP`
     - `INTEGRATION_SETTINGS.WEBHOOK.FORM.ACCESS_TOKEN.ENABLED`
     - `INTEGRATION_SETTINGS.WEBHOOK.FORM.ACCESS_TOKEN.DISABLED`

## Como Usar

1. Acesse **Configurações** > **Integrações** > **Webhook**
2. Crie ou edite um webhook
3. Marque a opção **"Include Access Token (SocialWise Integration)"**
4. Salve o webhook

## Payload do Webhook

Quando a opção está habilitada, o payload incluirá um campo adicional:

```json
{
  "event": "message_created",
  "account": {...},
  "conversation": {...},
  "message": {...},
  "ACCESS_TOKEN": "XzqGPinpcBhwkfyyjuyShBgD"
}
```

O `ACCESS_TOKEN` é o token de acesso do primeiro administrador da conta, que pode ser usado para fazer chamadas autenticadas à API do Chatwit.

## Execução da Migration

Execute o seguinte comando para aplicar a migration:

```bash
bundle exec rails db:migrate
```

## Notas de Segurança

- O ACCESS_TOKEN só é incluído se a opção estiver explicitamente habilitada
- O token pertence ao primeiro administrador da conta
- Recomenda-se usar HTTPS para URLs de webhook quando esta opção estiver habilitada
