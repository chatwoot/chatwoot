# Chatwoot -> Evolution API: что передаем и что можно передавать

## 1) Создание инстанса (`POST /instance/create`)

### Что передаем сейчас из Chatwoot (фактически)

```json
{
  "instanceName": "cw_<account_id>_<inbox_id>",
  "qrcode": false,
  "integration": "WHATSAPP-BAILEYS",
  "token": "<optional_if_configured>"
}
```

- `instanceName`: генерируется автоматически, если не задан вручную.
- `integration`: всегда `WHATSAPP-BAILEYS` для WhatsApp Web сценария.
- `qrcode: false`: QR получаем отдельным вызовом `/instance/connect/{instance}`.
- `token`: передается только если заполнен `WHATSAPP_WEB_INSTANCE_TOKEN`.

### Что обязательно для Evolution (runtime)

- `instanceName`
- `integration`

### Что можно передавать дополнительно в `create` (опционально)

- `number` (для pair code)
- `rejectCall`
- `msgCall`
- `groupsIgnore`
- `alwaysOnline`
- `readMessages`
- `readStatus`
- `syncFullHistory`
- `proxyHost`
- `proxyPort`
- `proxyProtocol`
- `proxyUsername`
- `proxyPassword`
- `webhook` (объект)
- `rabbitmq` (объект)
- `sqs` (объект)

Примечание: поля `chatwoot*` тоже могут быть переданы в `create`, но в нашей интеграции Chatwoot настраивается отдельным шагом через `/chatwoot/set/{instance}`.

## 2) Настройка интеграции Chatwoot (`POST /chatwoot/set/{instance}`)

### Что передаем сейчас из Chatwoot (фактически)

```json
{
  "enabled": true,
  "accountId": "<chatwoot_account_id>",
  "token": "<chatwoot_user_access_token>",
  "url": "<chatwoot_base_url>",
  "signMsg": false,
  "reopenConversation": false,
  "conversationPending": false,
  "importContacts": true,
  "mergeBrazilContacts": false,
  "importMessages": true,
  "daysLimitImportMessages": 60,
  "autoCreate": false,
  "nameInbox": "<chatwoot_inbox_name>"
}
```

### Что можно передавать дополнительно (опционально)

- `signDelimiter`
- `organization`
- `logo`
- `ignoreJids`

## 3) Логин устройства и QR

После `create` + `chatwoot/set` используются:

- `GET /instance/connect/{instance}` -> QR / pairing
- `GET /instance/connectionState/{instance}` -> статус
- `DELETE /instance/logout/{instance}` -> logout
- `DELETE /instance/delete/{instance}` -> удаление инстанса

## 4) Конфигурация окружений (dev/prod) без правок Evolution-кода

### Dev (Chatwoot локально, Postgres/Redis в Docker, Evolution в Docker)

1. В `chatwoot` создать `.env` из `.env.dev.example`.
2. Проверить в `chatwoot/.env`:
   - `WHATSAPP_WEB_EVOLUTION_BASE_URL = EVOLUTION_SERVER_URL`
   - `WHATSAPP_WEB_EVOLUTION_API_KEY = AUTHENTICATION_API_KEY`
3. Запуск dev-зависимостей (как у вас сейчас):

```bash
cd /Users/akhanbakhitov/Documents/zeroprompt/chatwoot
./script/dev-light --fresh --skip-db-prepare --ngrok
```

`script/dev-light` поднимает:
- `postgres`
- `redis`
- `evolution_api` на `127.0.0.1:8080`
- `evolution_manager` на `localhost:3003` (только dev)

### Prod (без manager, только API)

1. В `chatwoot` создать production `.env` из `.env.prod.example`.
2. В production `chatwoot/.env` задать URL/API key:
   - `WHATSAPP_WEB_EVOLUTION_BASE_URL=https://...`
   - `WHATSAPP_WEB_EVOLUTION_API_KEY=<тот же AUTHENTICATION_API_KEY>`
3. Запуск production стека Chatwoot + Evolution:

```bash
cd /Users/akhanbakhitov/Documents/zeroprompt/chatwoot
docker compose -f docker-compose.production.yaml up -d
```

### Что обязательно синхронизировать между Chatwoot и Evolution

- URL:
  - Chatwoot: `WHATSAPP_WEB_EVOLUTION_BASE_URL`
  - Evolution: `EVOLUTION_SERVER_URL`
- API key:
  - Chatwoot: `WHATSAPP_WEB_EVOLUTION_API_KEY` (или fallback `AUTHENTICATION_API_KEY`)
  - Evolution: `AUTHENTICATION_API_KEY`
