# InfinitePay Integration — Chatwit

> **Data:** 2026-03-10
> **Status:** IMPLEMENTADO
> **Handle de teste:** `amanda-57944155-29z`

---

## Visão Geral

Integração de links de pagamento InfinitePay no Chatwit. Agentes podem enviar cobranças de cartão de crédito e PIX diretamente na conversa com o cliente.

---

## Arquitetura

```
Agente clica "💰 Pagamento" na conversa
  → Modal: valor, descrição, favoritos
  → POST /api/v1/accounts/:id/payment_links { conversation_id, amount_cents, description }
    → CreateLinkService chama InfinitePay API
    → Cria PaymentLink (status: pending)
    → Envia mensagem com checkout_url na conversa

Cliente paga
  → InfinitePay envia webhook: POST /webhooks/infinitepay
    → WebhookProcessorService encontra PaymentLink por order_nsu
    → Atualiza status para "paid"
    → Envia mensagem de confirmação na conversa
    → Encaminha "payment.confirmed" para SocialWise e JusMonitorIA
    → Se `infinitepay_push_only=true`, envia push PWA exclusivo com o comprovante
```

---

## Configuração por Conta

Cada conta configura seu próprio InfinitePay handle em:
**Settings → Account Settings → InfinitePay Payments**

O handle é salvo em `account.custom_attributes['infinitepay_handle']`.

Opcionalmente, a conta pode ativar `account.custom_attributes['infinitepay_push_only']` na mesma tela para:
- silenciar os pushes padrão de conversa no PWA
- enviar apenas o push exclusivo do webhook da InfinitePay com a confirmação do pagamento

Sem handle configurado, o botão de pagamento não aparece na conversa.

---

## Taxas e Parcelas (InfinitePay)

A API pública de checkout da InfinitePay (`POST https://api.checkout.infinitepay.io/links`) **não oferece controle** sobre:
- Número de parcelas (o cliente escolhe no checkout)
- Quem paga a taxa (vendedor ou comprador)
- Tipo de recebimento (1 dia útil ou NITRO)

Essas configurações são feitas **exclusivamente no painel/app da InfinitePay**.

### Tabela de Taxas (plano padrão — recebimento em 1 dia útil)

| Tipo de Pagamento | Taxa |
|-------------------|------|
| Pix | 0,00% (Grátis) |
| Crédito à vista (1x) | 4,20% |
| Crédito em 2x | 6,09% |
| Crédito em 3x | 7,01% |
| Crédito em 4x | 7,91% |
| Crédito em 5x | 8,80% |
| Crédito em 6x | 9,67% |
| Crédito em 7x | 12,59% |
| Crédito em 8x | 13,42% |
| Crédito em 9x | 14,25% |
| Crédito em 10x | 15,06% |
| Crédito em 11x | 15,87% |
| Crédito em 12x | 16,66% |

### Opções configuráveis no painel InfinitePay

| Configuração | Descrição | Padrão |
|--------------|-----------|--------|
| Parcelas | Até quantas vezes o cliente pode parcelar | Definido no app |
| Taxa para o cliente | Repassa a taxa para o comprador | Desativado (vendedor absorve) |
| Recebimento NITRO | Recebimento na hora (taxa maior) | Desativado (1 dia útil) |

### Simulação no Modal

O modal de pagamento exibe um **simulador de taxas** (expansível) que calcula automaticamente o valor líquido que o vendedor receberá para cada forma de pagamento, baseado nas taxas do plano padrão (1 dia útil).

---

## API Endpoints

### `GET /api/v1/accounts/:account_id/payment_presets`
Lista favoritos de pagamento da conta.

### `POST /api/v1/accounts/:account_id/payment_presets`
Cria um favorito.
```json
{
  "payment_preset": {
    "name": "Consulta Inicial",
    "amount_cents": 15000,
    "description": "Consulta jurídica inicial"
  }
}
```

### `PATCH /api/v1/accounts/:account_id/payment_presets/:id`
Atualiza um favorito.

### `DELETE /api/v1/accounts/:account_id/payment_presets/:id`
Remove um favorito.

### `GET /api/v1/accounts/:account_id/payment_links`
Lista links de pagamento. Aceita `?conversation_id=` para filtrar.

### `POST /api/v1/accounts/:account_id/payment_links`
Cria e envia um link de pagamento.
```json
{
  "conversation_id": 123,
  "amount_cents": 10000,
  "description": "Honorários advocatícios"
}
```

### `POST /webhooks/infinitepay`
Recebe webhook de confirmação de pagamento do InfinitePay.

---

## Modelos de Dados

### PaymentPreset (Favoritos)
| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | integer | PK |
| `account_id` | integer | FK → accounts |
| `name` | string | Nome do favorito |
| `amount_cents` | integer | Valor em centavos |
| `description` | string | Descrição do item |

### PaymentLink (Links de Pagamento)
| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | integer | PK |
| `account_id` | integer | FK → accounts |
| `conversation_id` | integer | FK → conversations |
| `user_id` | integer | FK → users (agente) |
| `order_nsu` | string | NSU único (`chatwit-{account}-{conversation}-{hex}`) |
| `amount_cents` | integer | Valor em centavos |
| `description` | string | Descrição |
| `checkout_url` | string | URL do checkout InfinitePay |
| `status` | string | `pending`, `paid`, `expired` |
| `invoice_slug` | string | Slug da fatura InfinitePay |
| `transaction_nsu` | string | NSU da transação |
| `capture_method` | string | `pix` ou `credit_card` |
| `paid_amount_cents` | integer | Valor efetivamente pago |
| `receipt_url` | string | URL do comprovante |
| `webhook_payload` | jsonb | Payload completo do webhook |

---

## Arquivos Criados/Modificados

### Novos
| Arquivo | Descrição |
|---------|-----------|
| `db/migrate/20260310000001_create_payment_presets.rb` | Migration payment_presets |
| `db/migrate/20260310000002_create_payment_links.rb` | Migration payment_links |
| `app/models/payment_preset.rb` | Model PaymentPreset |
| `app/models/payment_link.rb` | Model PaymentLink |
| `app/policies/payment_preset_policy.rb` | Policy Pundit |
| `app/policies/payment_link_policy.rb` | Policy Pundit |
| `app/controllers/api/v1/accounts/payment_presets_controller.rb` | CRUD presets |
| `app/controllers/api/v1/accounts/payment_links_controller.rb` | Create/list links |
| `app/controllers/webhooks/infinitepay_controller.rb` | Webhook receiver |
| `lib/integrations/infinitepay/create_link_service.rb` | Cria link na API InfinitePay |
| `lib/integrations/infinitepay/webhook_processor_service.rb` | Processa webhook |
| `app/javascript/dashboard/api/paymentPresets.js` | API client presets |
| `app/javascript/dashboard/api/paymentLinks.js` | API client links |
| `app/javascript/dashboard/store/modules/paymentPresets.js` | Vuex store |
| `app/javascript/dashboard/components/widgets/conversation/PaymentLink/Modal.vue` | Modal de pagamento |
| `app/javascript/dashboard/routes/dashboard/settings/account/components/InfinitePaySettings.vue` | Settings component |
| `app/javascript/dashboard/i18n/locale/en/paymentLink.json` | i18n strings |

### Modificados
| Arquivo | Alteração |
|---------|-----------|
| `app/models/account.rb` | `has_many :payment_links, :payment_presets` |
| `config/routes.rb` | Rotas payment_presets, payment_links, webhook |
| `app/controllers/api/v1/accounts_controller.rb` | `infinitepay_handle` em custom_attributes_params |
| `app/javascript/dashboard/components/widgets/WootWriter/ReplyBottomPanel.vue` | Prop + botão 💰 |
| `app/javascript/dashboard/components/widgets/conversation/ReplyBox.vue` | Modal integration |
| `app/javascript/dashboard/store/index.js` | Import paymentPresets module |
| `app/javascript/dashboard/store/mutation-types.js` | Mutation types |
| `app/javascript/dashboard/i18n/locale/en/index.js` | Import paymentLink locale |
| `app/javascript/dashboard/i18n/locale/en/conversation.json` | FOOTER.PAYMENT_LINK |
| `app/javascript/dashboard/i18n/locale/en/generalSettings.json` | INFINITEPAY section |
| `app/javascript/dashboard/routes/dashboard/settings/account/Index.vue` | InfinitePaySettings component |

---

## Evento `payment.confirmed` (Forwarding)

Encaminhado para:
- **SocialWise:** `POST {SOCIALWISE_WEBHOOK_URL}/api/integrations/webhooks/socialwiseflow`
- **JusMonitorIA:** `POST {JUSMONITORIA_WEBHOOK_URL}/v1/integrations/chatwit`

### Logs de forwarding

O webhook agora registra explicitamente:
- sucesso no envio para SocialWise
- falha HTTP no envio para SocialWise com status code e trecho do body
- ausência de `SOCIALWISE_WEBHOOK_URL`
- sucesso no envio para JusMonitorIA
- envio do push PWA exclusivo da InfinitePay

Ver payloads detalhados em:
- `chatwitdocs/chatwit-contrato-async-30s copy.md` (Seção 17)
- `chatwitdocs/JusmonitorIA-contrato.md` (Seção 9)

---

## Variáveis de Ambiente

Nenhuma nova variável necessária. Reutiliza:
- `FRONTEND_URL` — para construir webhook_url do InfinitePay
- `SOCIALWISE_WEBHOOK_URL` — para forwarding de eventos
- `JUSMONITORIA_WEBHOOK_URL` — para forwarding de eventos
- `CHATWIT_WEBHOOK_SECRET` — para assinatura dos payloads

---

## Changelog

| Data | Descrição |
|------|-----------|
| 2026-03-10 | Implementação inicial: link de pagamento, favoritos, webhook, forwarding |
| 2026-03-11 | Modal: máscara de moeda (R$ 0,00), simulador de taxas por parcela, i18n pt_BR |
| 2026-03-11 | Modal: seletor de forma de pagamento (PIX/Cartão), parcelas, mensagem diferenciada por método, nota sobre checkout |
| 2026-05-07 | InfinitePay: endpoint de criação de links migrado para `https://api.checkout.infinitepay.io/links`; payloads e webhooks mantidos |
