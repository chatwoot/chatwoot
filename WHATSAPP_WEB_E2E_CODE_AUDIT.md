# Аудит источника WhatsApp Web (Chatwoot + Evolution API)

Дата: 28 февраля 2026  
Формат проверки: только статический анализ кода (без runtime/API вызовов)

## Область проверки

- Жизненный цикл источника: создание, setup, login, reconnect, logout, delete
- Входящие/исходящие сообщения
- Контакты и разговоры (conversations/chats)
- Синхронизация и импорт истории
- Сопоставление с паттернами других каналов Chatwoot (Telegram, WhatsApp Cloud, Instagram)

## Ключевые выводы

- Функционально контур WhatsApp Web через Evolution реализован почти полностью.
- Для production-качества есть 3 приоритетных риска: безопасность webhook, scoping instance на уровне inbox, жесткая привязка к `nameInbox`.
- Ограничение текущего этапа: код `evolution-api` не изменяем, фиксируем только `chatwoot` и инфраструктуру запуска.

## Findings (по критичности)

### 1) Critical: webhook Chatwoot в Evolution не защищен подписью/токеном

**Риск:** внешний отправитель может подделать событие и инициировать отправку сообщений в WhatsApp.

**Доказательства в коде:**

- Роут webhook без guard:
  - `POST /chatwoot/webhook/:instanceName`  
    [/Users/akhanbakhitov/Documents/zeroprompt/evolution-api/src/api/integrations/chatbot/chatwoot/routes/chatwoot.router.ts:33](/Users/akhanbakhitov/Documents/zeroprompt/evolution-api/src/api/integrations/chatbot/chatwoot/routes/chatwoot.router.ts:33)
- Обработка webhook ведет к исходящей отправке:
  [/Users/akhanbakhitov/Documents/zeroprompt/evolution-api/src/api/integrations/chatbot/chatwoot/services/chatwoot.service.ts:1444](/Users/akhanbakhitov/Documents/zeroprompt/evolution-api/src/api/integrations/chatbot/chatwoot/services/chatwoot.service.ts:1444)
- Chatwoot отправляет webhook без HMAC-подписи:
  [/Users/akhanbakhitov/Documents/zeroprompt/chatwoot/lib/webhooks/trigger.rb:24](/Users/akhanbakhitov/Documents/zeroprompt/chatwoot/lib/webhooks/trigger.rb:24)

**Решение простыми словами:**

- Добавить секрет между Chatwoot и Evolution (`WHATSAPP_WEB_WEBHOOK_SECRET`).
- Chatwoot при отправке webhook должен подписывать `payload` (HMAC-SHA256) и класть подпись в заголовок, например `X-Chatwoot-Signature`.
- Evolution в `POST /chatwoot/webhook/:instanceName` должен проверять подпись до обработки сообщения.
- Если подпись невалидна, сразу `401/403` и не отправлять ничего в WhatsApp.

**Что это даст:** никто снаружи не сможет “притвориться Chatwoot” и запустить отправку сообщений.

**Что можем сделать без правок Evolution:**

- Закрыть Evolution от внешнего интернета: только private Docker network между Chatwoot и Evolution.
- На reverse proxy оставить allowlist только для Chatwoot host/IP.
- В Chatwoot хранить webhook URL не публичным и с непредсказуемым сегментом пути.

**Что останется блокером до правок Evolution:**

- Полная криптографическая проверка подписи (`HMAC`) на webhook-входе возможна только при валидации в Evolution.

### 2) High: действия над instance можно направить на произвольный `instance_name`

**Риск:** админ inbox A может выполнять `status/login/reconnect/logout/remove` для instance, не связанного с inbox A.

**Доказательства в коде:**

- Используется `instance_name` из params без жесткой привязки к сохраненному:
  [/Users/akhanbakhitov/Documents/zeroprompt/chatwoot/app/controllers/api/v1/accounts/inboxes/whatsapp_web_controller.rb:382](/Users/akhanbakhitov/Documents/zeroprompt/chatwoot/app/controllers/api/v1/accounts/inboxes/whatsapp_web_controller.rb:382)
- Дальнейшие операции используют выбранное имя:
  [/Users/akhanbakhitov/Documents/zeroprompt/chatwoot/app/controllers/api/v1/accounts/inboxes/whatsapp_web_controller.rb:77](/Users/akhanbakhitov/Documents/zeroprompt/chatwoot/app/controllers/api/v1/accounts/inboxes/whatsapp_web_controller.rb:77)

**Решение простыми словами:**

- Для `status/login/reconnect/logout/remove/sync` брать `instance_name` только из сохраненной конфигурации inbox.
- Если фронт передал другой `instance_name`, игнорировать его и использовать “свой” из `additional_attributes.whatsapp_web.instance_name`.
- Для ручного override (если нужен админ-инструмент) сделать отдельный защищенный endpoint, а не общий UI flow.

**Что это даст:** каждый inbox управляет только своим instance, без риска затронуть чужой.

**Что можем сделать без правок Evolution:**

- Полностью фиксится в Chatwoot: игнорировать `instance_name` из params и брать только из конфигурации inbox.
- Добавить server-side проверку принадлежности instance к текущему inbox перед каждой операцией.

**Что останется блокером до правок Evolution:**

- Блокеров нет, если все операции идут только через Chatwoot API.

### 3) High: маршрутизация Evolution->Chatwoot завязана на `nameInbox`

**Риск:** при rename inbox или коллизиях имени возможно попадание входящих не в тот inbox.

**Доказательства в коде:**

- В Chatwoot `nameInbox` заполняется номером:
  [/Users/akhanbakhitov/Documents/zeroprompt/chatwoot/app/controllers/api/v1/accounts/inboxes/whatsapp_web_controller.rb:341](/Users/akhanbakhitov/Documents/zeroprompt/chatwoot/app/controllers/api/v1/accounts/inboxes/whatsapp_web_controller.rb:341)
- Имя inbox в Chatwoot меняется при изменении телефона:
  [/Users/akhanbakhitov/Documents/zeroprompt/chatwoot/app/controllers/api/v1/accounts/inboxes/whatsapp_web_controller.rb:250](/Users/akhanbakhitov/Documents/zeroprompt/chatwoot/app/controllers/api/v1/accounts/inboxes/whatsapp_web_controller.rb:250)
- В Evolution inbox ищется по имени:
  [/Users/akhanbakhitov/Documents/zeroprompt/evolution-api/src/api/integrations/chatbot/chatwoot/services/chatwoot.service.ts:909](/Users/akhanbakhitov/Documents/zeroprompt/evolution-api/src/api/integrations/chatbot/chatwoot/services/chatwoot.service.ts:909)

**Решение простыми словами:**

- Перестать использовать имя inbox как ключ маршрутизации.
- При первом `setup` сохранить стабильный идентификатор Chatwoot inbox (например `chatwoot_inbox_id`) в настройках Evolution/Chatwoot.
- Во всех последующих входящих/исходящих работать по этому ID, а не по `nameInbox`.
- Имя оставить только для отображения в UI.

**Что это даст:** переименование inbox или совпадение имен больше не ломает доставку и привязку диалогов.

**Что можем сделать без правок Evolution:**

- В Chatwoot зафиксировать `nameInbox = phone` и не давать свободный rename для WhatsApp Web inbox.
- Проверять уникальность такого имени в рамках account и не допускать коллизий.

**Что останется блокером до правок Evolution:**

- Полный переход на маршрутизацию по стабильному `chatwoot_inbox_id` невозможен без изменения логики поиска inbox в Evolution.

### 4) Medium: номер телефона искусственно ограничен 11 цифрами

**Риск:** региональные номера вне этого шаблона не пройдут валидацию (хуже, чем E.164-паттерн в других каналах).

**Доказательства в коде:**

- Backend:
  [/Users/akhanbakhitov/Documents/zeroprompt/chatwoot/app/controllers/api/v1/accounts/inboxes/whatsapp_web_controller.rb:5](/Users/akhanbakhitov/Documents/zeroprompt/chatwoot/app/controllers/api/v1/accounts/inboxes/whatsapp_web_controller.rb:5)
  [/Users/akhanbakhitov/Documents/zeroprompt/chatwoot/app/controllers/api/v1/accounts/inboxes/whatsapp_web_controller.rb:270](/Users/akhanbakhitov/Documents/zeroprompt/chatwoot/app/controllers/api/v1/accounts/inboxes/whatsapp_web_controller.rb:270)
- Frontend:
  [/Users/akhanbakhitov/Documents/zeroprompt/chatwoot/app/javascript/dashboard/routes/dashboard/settings/inbox/channels/whatsappWebPhone.js:1](/Users/akhanbakhitov/Documents/zeroprompt/chatwoot/app/javascript/dashboard/routes/dashboard/settings/inbox/channels/whatsappWebPhone.js:1)
  [/Users/akhanbakhitov/Documents/zeroprompt/chatwoot/app/javascript/dashboard/routes/dashboard/settings/inbox/channels/WhatsappWeb.vue:168](/Users/akhanbakhitov/Documents/zeroprompt/chatwoot/app/javascript/dashboard/routes/dashboard/settings/inbox/channels/WhatsappWeb.vue:168)

**Решение простыми словами:**

- Перейти на формат E.164: хранить номер как `+` и 8-15 цифр.
- В UI делать нормализацию и валидацию через libphonenumber (или эквивалент), а не жестко `11`.
- В backend валидировать тот же формат, что и на фронте, чтобы правила были одинаковые.

**Что это даст:** корректная работа не только для одного региона/длины номера.

**Что можем сделать без правок Evolution:**

- Полностью фиксится в Chatwoot: UI+backend валидация по E.164, единая нормализация номера.

**Что останется блокером до правок Evolution:**

- Блокеров нет, если Evolution принимает номер в том же формате.

### 5) Medium: неполный паритет статусов сообщений с официальным WhatsApp-каналом

**Риск:** read/delivery lifecycle по сообщениям отображается не полностью.

**Доказательства в коде:**

- В Evolution есть `messages.read` в сторону Chatwoot:
  [/Users/akhanbakhitov/Documents/zeroprompt/evolution-api/src/api/integrations/chatbot/chatwoot/services/chatwoot.service.ts:2408](/Users/akhanbakhitov/Documents/zeroprompt/evolution-api/src/api/integrations/chatbot/chatwoot/services/chatwoot.service.ts:2408)
- В official WhatsApp обработка статусов в Chatwoot выделена отдельным потоком:
  [/Users/akhanbakhitov/Documents/zeroprompt/chatwoot/app/services/whatsapp/incoming_message_base_service.rb:47](/Users/akhanbakhitov/Documents/zeroprompt/chatwoot/app/services/whatsapp/incoming_message_base_service.rb:47)

**Решение простыми словами:**

- Добавить явную маппинг-таблицу статусов Evolution -> Chatwoot (`sent/delivered/read/failed`).
- При событии `messages.update` обновлять статус конкретного сообщения в Chatwoot по `source_id`.
- Оставить текущий `update_last_seen` для UI-состояния, но не заменять им message-status.

**Что это даст:** статус каждого сообщения в Chatwoot станет предсказуемым и как в официальном WhatsApp-канале.

**Что можем сделать без правок Evolution:**

- В Chatwoot добавить явный mapping всех уже приходящих событий статусов.
- Доработать обновление статусов по `source_id` в собственном обработчике webhook.

**Что останется блокером до правок Evolution:**

- Полный паритет невозможен, если часть статусных событий не эмитится или эмитится неоднозначно на стороне Evolution.

### 6) Medium: sync/import завязаны на прямой доступ Evolution к БД Chatwoot

**Риск:** высокая связанность, чувствительность к схеме БД и окружению; сложнее безопасно переносить между инсталляциями.

**Доказательства в коде:**

- Проверка доступности import через DB URI:
  [/Users/akhanbakhitov/Documents/zeroprompt/evolution-api/src/api/integrations/chatbot/chatwoot/services/chatwoot.service.ts:2548](/Users/akhanbakhitov/Documents/zeroprompt/evolution-api/src/api/integrations/chatbot/chatwoot/services/chatwoot.service.ts:2548)
- Массовые SQL вставки/апдейты в helper:
  [/Users/akhanbakhitov/Documents/zeroprompt/evolution-api/src/api/integrations/chatbot/chatwoot/utils/chatwoot-import-helper.ts:98](/Users/akhanbakhitov/Documents/zeroprompt/evolution-api/src/api/integrations/chatbot/chatwoot/utils/chatwoot-import-helper.ts:98)

**Решение простыми словами:**

- Для MVP можно оставить DB-import, но ограничить его флагом и документацией “только для self-hosted”.
- Для основного production-пути постепенно перейти на API-импорт (batch через Chatwoot API) без прямых SQL в чужую БД.
- Если DB-import остается: параметризовать SQL, убрать строковую интерполяцию, добавить миграционные проверки версии схемы.

**Что это даст:** меньше хрупкости между версиями и меньше рисков при обновлениях.

**Что можем сделать без правок Evolution:**

- В Chatwoot отключить из UI рискованные сценарии `sync/import`, которые требуют DB-coupling.
- Оставить только безопасный online-flow (реалтайм webhook + reconnect).

**Что останется блокером до правок Evolution:**

- Убрать прямую зависимость от БД Chatwoot полностью можно только изменив import-архитектуру в Evolution.

### 7) Medium: дедупликация входящих не абсолютная

**Риск:** при гонках/повторных событиях возможны дубликаты в Chatwoot.

**Доказательства в коде:**

- Каждое `messages.upsert` отправляется в Chatwoot:
  [/Users/akhanbakhitov/Documents/zeroprompt/evolution-api/src/api/integrations/channel/whatsapp/whatsapp.baileys.service.ts:1331](/Users/akhanbakhitov/Documents/zeroprompt/evolution-api/src/api/integrations/channel/whatsapp/whatsapp.baileys.service.ts:1331)
- Запись сообщения в Chatwoot по `source_id`, без уникального индекса на `messages.source_id`:
  [/Users/akhanbakhitov/Documents/zeroprompt/evolution-api/src/api/integrations/chatbot/chatwoot/services/chatwoot.service.ts:946](/Users/akhanbakhitov/Documents/zeroprompt/evolution-api/src/api/integrations/chatbot/chatwoot/services/chatwoot.service.ts:946)
  [/Users/akhanbakhitov/Documents/zeroprompt/chatwoot/db/schema.rb:993](/Users/akhanbakhitov/Documents/zeroprompt/chatwoot/db/schema.rb:993)

**Решение простыми словами:**

- Перед созданием сообщения всегда проверять существование `source_id` в нужном `conversation/inbox`.
- Добавить защиту от гонок: idempotency key в Redis (`instance + source_id`) с `SET NX`.
- На уровне БД добавить уникальность хотя бы составным индексом для канала WhatsApp Web (например `inbox_id + source_id`), если не ломает другие каналы.

**Что это даст:** повторные webhook/события не будут создавать дубли.

**Что можем сделать без правок Evolution:**

- Полностью или почти полностью фиксится в Chatwoot: дедуп по `source_id`, idempotency-key в Redis, уникальный индекс для WhatsApp Web потока.

**Что останется блокером до правок Evolution:**

- При аномальных кейсах с разными `source_id` для одного фактического события потребуется нормализация на стороне Evolution.

## Матрица кейсов (статус)

### Lifecycle source

- Создание API inbox + WhatsApp Web setup: **есть**
- Получение QR и pair code: **есть**
- Reconnect/logout/remove instance: **есть**
- Привязка instance строго к inbox: **частично** (см. Finding #2)

### Сообщения

- Входящие text/media/reaction/group/edit/delete: **есть**
- Исходящие text/media/template/delete: **есть**
- Привязка reply chain (`in_reply_to`/quoted): **есть**
- Полный паритет delivery/read статусов с official WhatsApp: **частично** (см. Finding #5)

### Контакты/чаты

- Find/create/update contacts: **есть**
- Создание/переиспользование conversation с reopen/pending: **есть**
- Устойчивый identity mapping без зависимости от inbox name: **частично** (см. Finding #3)

### Sync/Import

- Импорт контактов и истории сообщений: **есть**
- Sync lost messages после reconnect: **есть**
- Слабая связность (без DB-level coupling): **нет** (см. Finding #6)

## Сравнение с другими каналами Chatwoot

- Telegram/Instagram/официальный WhatsApp в Chatwoot интегрированы через специализированные channel services с более жесткой валидацией входящих провайдерских webhook.
- WhatsApp Web через Evolution строится через `Channel::Api` webhook-модель и переносит значимую часть бизнес-логики в Evolution (контакты/чаты/дедуп/import), из-за чего:
  - повышается зависимость от версии Evolution;
  - растет чувствительность к конфигурации и DB-доступу;
  - требуется дополнительное hardening на границе webhook безопасности.

## Приоритет исправлений

1. Защитить `POST /chatwoot/webhook/:instanceName` (подпись/HMAC + проверка источника).
2. Запретить override `instance_name` извне, либо валидировать соответствие `inbox -> stored instance_name`.
3. Убрать routing по `nameInbox`, перейти на стабильный ключ (`inbox_id`/`identifier`), передаваемый и проверяемый обеими сторонами.
4. Ослабить валидацию номера до E.164.
5. Дожать паритет message status flow.

## Приоритет исправлений в рамках ограничения (Evolution не меняем)

1. Закрыть Evolution на сетевом уровне (private network + allowlist), убрать публичный доступ webhook.
2. В Chatwoot жестко фиксировать `instance_name` из inbox-конфига и запретить override из params.
3. Зафиксировать и валидировать `nameInbox = phone` (уникальность в account), убрать коллизии.
4. Перевести валидацию телефона на E.164 в UI и backend.
5. Включить idempotency/dedup в Chatwoot по `source_id` и добавить защиту от гонок.
6. Отключить из UI/flow сценарии sync/import, требующие прямого DB-coupling.

## Что принципиально не закрыть без правок Evolution

- Валидацию HMAC-подписи входящего webhook.
- Полную маршрутизацию по стабильному `inbox_id` вместо `nameInbox`.
- Полный паритет статусов сообщений, если нужные события не отдаются Evolution.
- Полное устранение DB-coupling import-пути.

## ENV-only hardening для Evolution (без правок кода)

Ниже настройки, которые можно и нужно делать только через `env`/`docker-compose`.

### Базовый набор (обязательно)

- `AUTHENTICATION_API_KEY=<длинный случайный ключ>`
- `AUTHENTICATION_EXPOSE_IN_FETCH_INSTANCES=false`
- `EVOLUTION_BIND_ADDRESS=127.0.0.1`
- `EVOLUTION_DEL_INSTANCE=false`
- `EVOLUTION_LOG_LEVEL=ERROR,WARN,INFO`
- `EVOLUTION_CHATWOOT_MESSAGE_READ=true`
- `EVOLUTION_CHATWOOT_MESSAGE_DELETE=true`
- `EVOLUTION_CACHE_REDIS_SAVE_INSTANCES=true`
- `EVOLUTION_QRCODE_COLOR=000000`

### CORS (с учетом текущего поведения Evolution v2)

- `EVOLUTION_CORS_ORIGIN=*`
- `EVOLUTION_CORS_METHODS=GET,POST,PUT,DELETE`
- `EVOLUTION_CORS_CREDENTIALS=true`

Причина: в server-to-server вызовах от Chatwoot обычно нет заголовка `Origin`; при жестком `CORS_ORIGIN` не `*` возможны 4xx ответы.
Безопасность в таком режиме достигается не CORS, а сетевой изоляцией (`127.0.0.1`, private network, reverse-proxy allowlist).

### Для production

- `EVOLUTION_SERVER_URL=https://<ваш-evolution-домен>`
- `EVOLUTION_API_IMAGE=evoapicloud/evolution-api:<зафиксированный-тег>`
- `EVOLUTION_DATABASE_CONNECTION_URI=postgresql://.../chatwoot?schema=evolution_api`
- `EVOLUTION_CACHE_REDIS_URI=redis://.../6`
- `CHATWOOT_IMPORT_DATABASE_CONNECTION_URI=postgresql://.../chatwoot?sslmode=disable` (оставлять только если реально используете import/sync)

### Что именно это закрывает

- Снижает риск внешнего доступа к API Evolution.
- Убирает утечку токенов/служебных данных через `fetchInstances`.
- Исключает случайное удаление instance таймером.
- Делает состояние сессий стабильнее при рестартах (Redis persistence).
- Снижает риск попадания чувствительных данных в логи.

### Что env не решит

- Проверку HMAC-подписи webhook от Chatwoot на входе Evolution.
- Переход маршрутизации с `nameInbox` на стабильный `inbox_id`.
- Архитектурную зависимость import от прямого доступа Evolution к БД Chatwoot.

## Что проверялось как первоисточник

- Код Chatwoot:
  - [/Users/akhanbakhitov/Documents/zeroprompt/chatwoot/app/controllers/api/v1/accounts/inboxes/whatsapp_web_controller.rb](/Users/akhanbakhitov/Documents/zeroprompt/chatwoot/app/controllers/api/v1/accounts/inboxes/whatsapp_web_controller.rb)
  - [/Users/akhanbakhitov/Documents/zeroprompt/chatwoot/app/services/whatsapp_web/connector_client.rb](/Users/akhanbakhitov/Documents/zeroprompt/chatwoot/app/services/whatsapp_web/connector_client.rb)
  - [/Users/akhanbakhitov/Documents/zeroprompt/chatwoot/app/javascript/dashboard/routes/dashboard/settings/inbox/FinishSetup.vue](/Users/akhanbakhitov/Documents/zeroprompt/chatwoot/app/javascript/dashboard/routes/dashboard/settings/inbox/FinishSetup.vue)
- Код Evolution:
  - [/Users/akhanbakhitov/Documents/zeroprompt/evolution-api/src/api/integrations/chatbot/chatwoot/services/chatwoot.service.ts](/Users/akhanbakhitov/Documents/zeroprompt/evolution-api/src/api/integrations/chatbot/chatwoot/services/chatwoot.service.ts)
  - [/Users/akhanbakhitov/Documents/zeroprompt/evolution-api/src/api/integrations/channel/whatsapp/whatsapp.baileys.service.ts](/Users/akhanbakhitov/Documents/zeroprompt/evolution-api/src/api/integrations/channel/whatsapp/whatsapp.baileys.service.ts)
  - [/Users/akhanbakhitov/Documents/zeroprompt/evolution-api/src/api/integrations/chatbot/chatwoot/routes/chatwoot.router.ts](/Users/akhanbakhitov/Documents/zeroprompt/evolution-api/src/api/integrations/chatbot/chatwoot/routes/chatwoot.router.ts)
- Доки Evolution/OpenAPI:
  - [/Users/akhanbakhitov/Documents/zeroprompt/docs-evolution/openapi/openapi-v2.json](/Users/akhanbakhitov/Documents/zeroprompt/docs-evolution/openapi/openapi-v2.json)
  - [/Users/akhanbakhitov/Documents/zeroprompt/chatwoot/API_ENDPOINTS_GUIDE_RU.md](/Users/akhanbakhitov/Documents/zeroprompt/chatwoot/API_ENDPOINTS_GUIDE_RU.md)
