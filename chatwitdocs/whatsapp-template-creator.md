# WhatsApp Template Creator — Documentação

> **Feature:** Criação de templates WhatsApp diretamente do modal de templates no chat
> **Data:** 2026-03-10
> **Status:** Implementado

---

## Visão Geral

Permite que **administradores** criem templates WhatsApp simples (header texto, body, footer, botões quick reply) diretamente do modal de templates na conversa. O template é submetido à Meta Graph API para aprovação.

### Fluxo

```
Admin abre modal de templates → clica "Create Template"
  ↓
Preenche: nome (snake_case), categoria, idioma, header, body, footer, botões
  ↓ POST /api/v1/accounts/{id}/inboxes/{id}/whatsapp_templates
TemplateCreatorService valida e envia à Meta API
  ↓ POST https://graph.facebook.com/v22.0/{WABA_ID}/message_templates
Meta retorna: { id, status: "PENDING" }
  ↓
Após aprovação da Meta + próximo sync → template aparece na lista
```

---

## Escopo (MVP)

| Suportado | Não suportado (futuro) |
|-----------|----------------------|
| Header TEXT | Headers de mídia (IMAGE/VIDEO/DOCUMENT) |
| Body com `{{variáveis}}` | Botões URL / PHONE_NUMBER / COPY_CODE |
| Footer texto | Edição de templates |
| Botões QUICK_REPLY (max 10) | Exclusão de templates |
| Categorias MARKETING / UTILITY | Polling de status |
| Idioma pré-preenchido pt_BR | AUTHENTICATION templates |

---

## Permissões

- **Quem pode criar:** Somente administradores (`InboxPolicy#create_whatsapp_template?`)
- **Onde aparece:** Botão "Create Template" no modal de templates, visível apenas para admins
- **Canais suportados:** WhatsApp Cloud (provider `whatsapp_cloud`)

---

## Meta API Payload

Formato enviado pela `Whatsapp::TemplateCreatorService`:

```json
{
  "name": "boas_vindas_cliente",
  "category": "UTILITY",
  "language": "pt_BR",
  "components": [
    {
      "type": "HEADER",
      "format": "TEXT",
      "text": "Olá {{nome}}",
      "example": { "header_text": ["example_nome"] }
    },
    {
      "type": "BODY",
      "text": "Seu pedido {{numero}} está em processamento.",
      "example": { "body_text": [["example_numero"]] }
    },
    {
      "type": "FOOTER",
      "text": "Equipe Suporte"
    },
    {
      "type": "BUTTONS",
      "buttons": [
        { "type": "QUICK_REPLY", "text": "Confirmar" },
        { "type": "QUICK_REPLY", "text": "Cancelar" }
      ]
    }
  ]
}
```

### Regras de Validação

| Campo | Regra |
|-------|-------|
| `name` | Obrigatório, snake_case: `/^[a-z][a-z0-9_]*$/` |
| `body_text` | Obrigatório, max 1024 chars |
| `header_text` | Opcional, max 60 chars |
| `footer_text` | Opcional, max 60 chars |
| Buttons | Max 10, cada texto max 25 chars |
| Variáveis | Formato `{{nome_variavel}}` |

---

## Arquivos

### Novos

| Arquivo | Descrição |
|---------|-----------|
| `app/services/whatsapp/template_creator_service.rb` | Service que valida e envia template à Meta API |
| `app/controllers/api/v1/accounts/inboxes/whatsapp_templates_controller.rb` | Controller REST (action: create) |
| `app/javascript/.../WhatsappTemplates/TemplateCreator.vue` | Componente Vue do formulário de criação + preview |

### Modificados

| Arquivo | Mudança |
|---------|---------|
| `config/routes.rb` | Adicionado `resources :whatsapp_templates` dentro do bloco `inboxes` |
| `app/policies/inbox_policy.rb` | Adicionado `create_whatsapp_template?` (admin-only) |
| `app/javascript/dashboard/api/inboxes.js` | Adicionado `createWhatsappTemplate()` |
| `app/javascript/dashboard/store/modules/inboxes.js` | Adicionado action `createWhatsappTemplate` |
| `app/javascript/.../WhatsappTemplates/Modal.vue` | Adicionado view `create` + botão "Create Template" para admins |
| `app/javascript/dashboard/i18n/locale/en/whatsappTemplates.json` | Adicionado bloco `CREATOR` com todas as strings i18n |

---

## Endpoint API

```
POST /api/v1/accounts/{account_id}/inboxes/{inbox_id}/whatsapp_templates

Headers:
  api_access_token: <admin_token>
  Content-Type: application/json

Body:
{
  "template": {
    "name": "meu_template",
    "category": "UTILITY",
    "language": "pt_BR",
    "header_text": "Olá {{nome}}",
    "body_text": "Seu pedido {{numero}} foi confirmado.",
    "footer_text": "Equipe Suporte",
    "buttons": [
      { "type": "QUICK_REPLY", "text": "Confirmar" },
      { "type": "QUICK_REPLY", "text": "Cancelar" }
    ]
  }
}

Response (200):
{
  "success": true,
  "template_id": "123456789",
  "template_name": "meu_template",
  "language": "pt_BR",
  "status": "PENDING"
}

Response (422 - validação):
{
  "errors": ["Name is required", "Body text is required"]
}

Response (422 - Meta API error):
{
  "error": "Message from Meta API",
  "response_code": 400
}
```

---

## Limitações Conhecidas

1. **Sem polling de status** — após criação, o status fica PENDING. O template só aparece na lista de envio após aprovação pela Meta + próximo sync automático (ou manual via botão "Refresh").
2. **Sem edição** — templates criados só podem ser editados via Meta Business Manager.
3. **Sem mídia** — headers de imagem/vídeo/documento não são suportados neste MVP.
4. **Sem botões avançados** — apenas QUICK_REPLY. URL, PHONE_NUMBER, COPY_CODE etc. não incluídos.
5. **API v22.0** — usa a versão mais recente da Graph API. Se a Meta deprecar, atualizar `WHATSAPP_API_VERSION` no service.
