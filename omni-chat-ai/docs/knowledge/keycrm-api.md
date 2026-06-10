# KeyCRM API — integration notes

- **Base URL:** `https://openapi.keycrm.app/v1`
- **Auth:** `Authorization: Bearer <API-key>` (Settings → generate API key).
- **Rate limit:** **60 requests/min per IP per key** → cache, batch, use `?limit=50`, pace ~1s.
- **Interactive docs:** https://docs.keycrm.app/ (Swagger). Community MCP: `IvanKlymenko/keycrm-mcp`.

## Objects / endpoints used by agents
- **Buyers:** `GET/POST/PUT /buyer`, `/buyer/{id}` (lookup by phone/email for context).
- **Orders:** `GET /order`, `GET /order/{id}?include=buyer,payments` (status, total, history),
  `POST/PUT /order` (create/update on sale).
- **Products/Offers/Stock:** `GET /products`, `GET /offers`, `GET /offers/stocks` (in-stock upsell).
- **Pipelines/Cards (leads):** `POST /pipelines/cards`, `GET /pipelines/cards/{id}`.

## Webhooks (trigger automation → "Send Webhook")
- `order.change_order_status`, `order.change_payment_status`, `lead.change_lead_status`,
  product/stock balance change. Payload is minimal → enrich via `GET /order/{id}`.

## Mapping
- KeyCRM **buyer** ↔ Chatwoot **contact** via phone/email or a stored external id custom field.
- Store the Chatwoot conversation reference on the order/card as a custom field.
