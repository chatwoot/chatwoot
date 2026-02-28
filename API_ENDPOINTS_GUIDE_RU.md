# Evolution API: практический справочник по API (из кода проекта)

Сгенерировано автоматически из роутеров и JSON-схем проекта. Всего найдено эндпоинтов: **184** (API: **183**, manager/static: **1**).

## Базовые правила вызова

- Базовый URL: `http://<host>:<port>` (см. `.env`, `SERVER_URL`).
- Основная авторизация: заголовок `apikey: <YOUR_KEY>`.
- Для большинства маршрутов используется `:instanceName` в path (пример: `/message/sendText/my-instance`).
- Для upload-маршрутов (`sendMedia/sendPtv/sendWhatsAppAudio/sendStatus/sendSticker`) нужен `multipart/form-data` + поле `file`.
- Если схема отсутствует (`schema: null`), сервер всё равно может ожидать query/body по логике контроллера.
- Типовой формат ошибки (глобальный middleware):

```json
{
  "status": 400,
  "error": "Bad Request",
  "response": {
    "message": "..."
  }
}
```

## Быстрые примеры

```bash
# Проверка API
curl -X GET "http://localhost:8080/"

# Создание инстанса
curl -X POST "http://localhost:8080/instance/create" -H "Content-Type: application/json" -H "apikey: <GLOBAL_API_KEY>" -d '{"instanceName":"my-instance","token":"secret","qrcode":true,"integration":"WHATSAPP-BAILEYS"}'

# Отправка текста
curl -X POST "http://localhost:8080/message/sendText/my-instance" -H "Content-Type: application/json" -H "apikey: <GLOBAL_OR_INSTANCE_TOKEN>" -d '{"number":"79991234567","text":"Привет"}'

# Загрузка media
curl -X POST "http://localhost:8080/message/sendMedia/my-instance" -H "apikey: <GLOBAL_OR_INSTANCE_TOKEN>" -F "file=@/tmp/image.jpg" -F "number=79991234567" -F "mediatype=image"
```

## Каталог эндпоинтов

Колонки: `Auth` = нужен ли `apikey`; `Schema` = валидация запроса + обязательные поля; `Status` = коды, которые явно выставляются в роуте.

### root

| Method | Path | Auth | Content-Type | Schema | Status |
|---|---|---|---|---|---|
| GET | `/` | no | — | — | 200 |

### instance

| Method | Path | Auth | Content-Type | Schema | Status |
|---|---|---|---|---|---|
| GET | `/instance/connect/:instanceName` | yes | — | — | 200 |
| GET | `/instance/connectionState/:instanceName` | yes | — | — | 200 |
| POST | `/instance/create` | yes | json | `instanceSchema` (runtime: требуется `integration`) | 201 |
| DELETE | `/instance/delete/:instanceName` | yes | json | — | 200 |
| GET | `/instance/fetchInstances` | yes | — | — | 200 |
| DELETE | `/instance/logout/:instanceName` | yes | json | — | 200 |
| POST | `/instance/restart/:instanceName` | yes | json | — | 200 |
| POST | `/instance/setPresence/:instanceName` | yes | json | `presenceOnlySchema` (req: presence) | 201 |

### message

| Method | Path | Auth | Content-Type | Schema | Status |
|---|---|---|---|---|---|
| POST | `/message/sendButtons/:instanceName` | yes | json | `buttonsMessageSchema` (req: number) | 201 |
| POST | `/message/sendContact/:instanceName` | yes | json | `contactMessageSchema` (req: number, contact) | 201 |
| POST | `/message/sendList/:instanceName` | yes | json | `listMessageSchema` (req: number, title, footerText, buttonText, sections) | 201 |
| POST | `/message/sendLocation/:instanceName` | yes | json | `locationMessageSchema` (req: number, latitude, longitude, name, address) | 201 |
| POST | `/message/sendMedia/:instanceName` | yes | multipart/form-data | `mediaMessageSchema` (req: number, mediatype) | 201 |
| POST | `/message/sendPoll/:instanceName` | yes | json | `pollMessageSchema` (req: number, name, selectableCount, values) | 201 |
| POST | `/message/sendPtv/:instanceName` | yes | multipart/form-data | `ptvMessageSchema` (req: number) | 201 |
| POST | `/message/sendReaction/:instanceName` | yes | json | `reactionMessageSchema` (req: key, reaction) | 201 |
| POST | `/message/sendStatus/:instanceName` | yes | multipart/form-data | `statusMessageSchema` (req: type) | 201 |
| POST | `/message/sendSticker/:instanceName` | yes | multipart/form-data | `stickerMessageSchema` (req: number) | 201 |
| POST | `/message/sendTemplate/:instanceName` | yes | json | `templateMessageSchema` (req: name, language) | 201 |
| POST | `/message/sendText/:instanceName` | yes | json | `textMessageSchema` (req: number, text) | 201 |
| POST | `/message/sendWhatsAppAudio/:instanceName` | yes | multipart/form-data | `audioMessageSchema` (req: number) | 201 |

### call

| Method | Path | Auth | Content-Type | Schema | Status |
|---|---|---|---|---|---|
| POST | `/call/offer/:instanceName` | yes | json | `offerCallSchema` (req: number, callDuration) | 201 |

### chat

| Method | Path | Auth | Content-Type | Schema | Status |
|---|---|---|---|---|---|
| POST | `/chat/archiveChat/:instanceName` | yes | json | `archiveChatSchema` (req: archive) | 201 |
| DELETE | `/chat/deleteMessageForEveryone/:instanceName` | yes | json | `deleteMessageSchema` (req: id, fromMe, remoteJid) | 201 |
| POST | `/chat/fetchBusinessProfile/:instanceName` | yes | json | `profilePictureSchema` (req: нет обязательных) | 200 |
| GET | `/chat/fetchPrivacySettings/:instanceName` | yes | — | — | 200 |
| POST | `/chat/fetchProfile/:instanceName` | yes | json | `profileSchema` (req: нет обязательных) | 200 |
| POST | `/chat/fetchProfilePictureUrl/:instanceName` | yes | json | `profilePictureSchema` (req: нет обязательных) | 200 |
| GET | `/chat/findChatByRemoteJid/:instanceName` | yes | — | — | 400, 200 |
| POST | `/chat/findChats/:instanceName` | yes | json | `contactValidateSchema` (req: нет обязательных) | 200 |
| POST | `/chat/findContacts/:instanceName` | yes | json | `contactValidateSchema` (req: нет обязательных) | 200 |
| POST | `/chat/findMessages/:instanceName` | yes | json | `messageValidateSchema` (req: нет обязательных) | 200 |
| POST | `/chat/findStatusMessage/:instanceName` | yes | json | `messageUpSchema` (req: нет обязательных) | 200 |
| POST | `/chat/getBase64FromMediaMessage/:instanceName` | yes | json | — | 201 |
| POST | `/chat/markChatUnread/:instanceName` | yes | json | `markChatUnreadSchema` (req: lastMessage) | 201 |
| POST | `/chat/markMessageAsRead/:instanceName` | yes | json | `readMessageSchema` (req: readMessages) | 201 |
| DELETE | `/chat/removeProfilePicture/:instanceName` | yes | json | `profilePictureSchema` (req: нет обязательных) | 200 |
| POST | `/chat/sendPresence/:instanceName` | yes | json | `presenceSchema` (req: number, presence, delay) | 201 |
| POST | `/chat/updateBlockStatus/:instanceName` | yes | json | `blockUserSchema` (req: number, status) | 201 |
| POST | `/chat/updateMessage/:instanceName` | yes | json | `updateMessageSchema` (req: нет обязательных) | 200 |
| POST | `/chat/updatePrivacySettings/:instanceName` | yes | json | `privacySettingsSchema` (req: readreceipts, profile, status, online, last, groupadd) | 201 |
| POST | `/chat/updateProfileName/:instanceName` | yes | json | `profileNameSchema` (req: нет обязательных) | 200 |
| POST | `/chat/updateProfilePicture/:instanceName` | yes | json | `profilePictureSchema` (req: нет обязательных) | 200 |
| POST | `/chat/updateProfileStatus/:instanceName` | yes | json | `profileStatusSchema` (req: нет обязательных) | 200 |
| POST | `/chat/whatsappNumbers/:instanceName` | yes | json | `whatsappNumberSchema` (req: нет обязательных) | 200, 400 |

### business

| Method | Path | Auth | Content-Type | Schema | Status |
|---|---|---|---|---|---|
| POST | `/business/getCatalog/:instanceName` | yes | json | `catalogSchema` (req: нет обязательных) | 200, errorResponse.status |
| POST | `/business/getCollections/:instanceName` | yes | json | `collectionsSchema` (req: нет обязательных) | 200, errorResponse.status |

### group

| Method | Path | Auth | Content-Type | Schema | Status |
|---|---|---|---|---|---|
| GET | `/group/acceptInviteCode/:instanceName` | yes | query/path | `AcceptGroupInviteSchema` (req: inviteCode) | 200 |
| POST | `/group/create/:instanceName` | yes | json | `createGroupSchema` (req: subject, participants) | 201 |
| GET | `/group/fetchAllGroups/:instanceName` | yes | query/path | `getParticipantsSchema` (req: getParticipants) | 200 |
| GET | `/group/findGroupInfos/:instanceName` | yes | query/path | `groupJidSchema` (req: groupJid) | 200 |
| GET | `/group/inviteCode/:instanceName` | yes | query/path | `groupJidSchema` (req: groupJid) | 200 |
| GET | `/group/inviteInfo/:instanceName` | yes | query/path | `groupInviteSchema` (req: inviteCode) | 200 |
| DELETE | `/group/leaveGroup/:instanceName` | yes | json | — | 200 |
| GET | `/group/participants/:instanceName` | yes | query/path | `groupJidSchema` (req: groupJid) | 200 |
| POST | `/group/revokeInviteCode/:instanceName` | yes | json | `groupJidSchema` (req: groupJid) | 201 |
| POST | `/group/sendInvite/:instanceName` | yes | json | `groupSendInviteSchema` (req: groupJid, description, numbers) | 200 |
| POST | `/group/toggleEphemeral/:instanceName` | yes | json | `toggleEphemeralSchema` (req: groupJid, expiration) | 201 |
| POST | `/group/updateGroupDescription/:instanceName` | yes | json | `updateGroupDescriptionSchema` (req: groupJid, description) | 201 |
| POST | `/group/updateGroupPicture/:instanceName` | yes | json | `updateGroupPictureSchema` (req: groupJid, image) | 201 |
| POST | `/group/updateGroupSubject/:instanceName` | yes | json | `updateGroupSubjectSchema` (req: groupJid, subject) | 201 |
| POST | `/group/updateParticipant/:instanceName` | yes | json | `updateParticipantsSchema` (req: groupJid, action, participants) | 201 |
| POST | `/group/updateSetting/:instanceName` | yes | json | `updateSettingsSchema` (req: groupJid, action) | 201 |

### template

| Method | Path | Auth | Content-Type | Schema | Status |
|---|---|---|---|---|---|
| POST | `/template/create/:instanceName` | yes | json | `templateSchema` (req: name, category, language, components) | 201, errorResponse.status |
| DELETE | `/template/delete/:instanceName` | yes | json | `templateDeleteSchema` (req: name) | 200, errorResponse.status |
| POST | `/template/edit/:instanceName` | yes | json | `templateEditSchema` (req: templateId) | 200, errorResponse.status |
| GET | `/template/find/:instanceName` | yes | query/path | `instanceSchema` (req: нет обязательных) | 200, errorResponse.status |

### settings

| Method | Path | Auth | Content-Type | Schema | Status |
|---|---|---|---|---|---|
| GET | `/settings/find/:instanceName` | yes | — | — | 200 |
| POST | `/settings/set/:instanceName` | yes | json | `settingsSchema` (req: rejectCall, groupsIgnore, alwaysOnline, readMessages, readStatus, syncFullHistory) | 201 |

### proxy

| Method | Path | Auth | Content-Type | Schema | Status |
|---|---|---|---|---|---|
| GET | `/proxy/find/:instanceName` | yes | query/path | `instanceSchema` (req: нет обязательных) | 200 |
| POST | `/proxy/set/:instanceName` | yes | json | `proxySchema` (req: enabled, host, port, protocol) | 201 |

### label

| Method | Path | Auth | Content-Type | Schema | Status |
|---|---|---|---|---|---|
| GET | `/label/findLabels/:instanceName` | yes | — | — | 200 |
| POST | `/label/handleLabel/:instanceName` | yes | json | `handleLabelSchema` (req: number, labelId, action) | 200 |

### baileys

| Method | Path | Auth | Content-Type | Schema | Status |
|---|---|---|---|---|---|
| POST | `/baileys/assertSessions/:instanceName` | yes | json | `instanceSchema` (req: нет обязательных) | 200 |
| POST | `/baileys/createParticipantNodes/:instanceName` | yes | json | `instanceSchema` (req: нет обязательных) | 200 |
| POST | `/baileys/generateMessageTag/:instanceName` | yes | json | `instanceSchema` (req: нет обязательных) | 200 |
| POST | `/baileys/getAuthState/:instanceName` | yes | json | `instanceSchema` (req: нет обязательных) | 200 |
| POST | `/baileys/getUSyncDevices/:instanceName` | yes | json | `instanceSchema` (req: нет обязательных) | 200 |
| POST | `/baileys/onWhatsapp/:instanceName` | yes | json | `instanceSchema` (req: нет обязательных) | 200 |
| POST | `/baileys/profilePictureUrl/:instanceName` | yes | json | `instanceSchema` (req: нет обязательных) | 200 |
| POST | `/baileys/sendNode/:instanceName` | yes | json | `instanceSchema` (req: нет обязательных) | 200 |
| POST | `/baileys/signalRepositoryDecryptMessage/:instanceName` | yes | json | `instanceSchema` (req: нет обязательных) | 200 |

### webhook

| Method | Path | Auth | Content-Type | Schema | Status |
|---|---|---|---|---|---|
| POST | `/webhook/evolution` | no | json | — | 200 |
| GET | `/webhook/find/:instanceName` | yes | query/path | `instanceSchema` (req: нет обязательных) | 200 |
| GET | `/webhook/meta` | no | — | — | — |
| POST | `/webhook/meta` | no | json | — | 200 |
| POST | `/webhook/set/:instanceName` | yes | json | `webhookSchema` (req: webhook) | 201 |

### websocket

| Method | Path | Auth | Content-Type | Schema | Status |
|---|---|---|---|---|---|
| GET | `/websocket/find/:instanceName` | yes | query/path | `instanceSchema` (req: нет обязательных) | 200 |
| POST | `/websocket/set/:instanceName` | yes | json | `eventSchema` (req: enabled) | 201 |

### rabbitmq

| Method | Path | Auth | Content-Type | Schema | Status |
|---|---|---|---|---|---|
| GET | `/rabbitmq/find/:instanceName` | yes | query/path | `instanceSchema` (req: нет обязательных) | 200 |
| POST | `/rabbitmq/set/:instanceName` | yes | json | `eventSchema` (req: enabled) | 201 |

### nats

| Method | Path | Auth | Content-Type | Schema | Status |
|---|---|---|---|---|---|
| GET | `/nats/find/:instanceName` | yes | query/path | `instanceSchema` (req: нет обязательных) | 200 |
| POST | `/nats/set/:instanceName` | yes | json | `eventSchema` (req: enabled) | 201 |

### pusher

| Method | Path | Auth | Content-Type | Schema | Status |
|---|---|---|---|---|---|
| GET | `/pusher/find/:instanceName` | yes | query/path | `instanceSchema` (req: нет обязательных) | 200 |
| POST | `/pusher/set/:instanceName` | yes | json | `pusherSchema` (req: pusher) | 201 |

### sqs

| Method | Path | Auth | Content-Type | Schema | Status |
|---|---|---|---|---|---|
| GET | `/sqs/find/:instanceName` | yes | query/path | `instanceSchema` (req: нет обязательных) | 200 |
| POST | `/sqs/set/:instanceName` | yes | json | `eventSchema` (req: enabled) | 201 |

### kafka

| Method | Path | Auth | Content-Type | Schema | Status |
|---|---|---|---|---|---|
| GET | `/kafka/find/:instanceName` | yes | query/path | `instanceSchema` (req: нет обязательных) | 200 |
| POST | `/kafka/set/:instanceName` | yes | json | `eventSchema` (req: enabled) | 201 |

### chatwoot

| Method | Path | Auth | Content-Type | Schema | Status |
|---|---|---|---|---|---|
| GET | `/chatwoot/find/:instanceName` | yes | query/path | `instanceSchema` (req: нет обязательных) | 200 |
| POST | `/chatwoot/set/:instanceName` | yes | json | `chatwootSchema` (req: enabled, accountId, token, url, signMsg, reopenConversation, conversationPending) | 201 |
| POST | `/chatwoot/webhook/:instanceName` | no | json | `instanceSchema` (req: нет обязательных) | 200 |

### typebot

| Method | Path | Auth | Content-Type | Schema | Status |
|---|---|---|---|---|---|
| POST | `/typebot/changeStatus/:instanceName` | yes | json | `typebotStatusSchema` (req: remoteJid, status) | 200 |
| POST | `/typebot/create/:instanceName` | yes | json | `typebotSchema` (req: enabled, url, typebot, triggerType) | 201 |
| DELETE | `/typebot/delete/:typebotId/:instanceName` | yes | json | `instanceSchema` (req: нет обязательных) | 200 |
| GET | `/typebot/fetch/:typebotId/:instanceName` | yes | query/path | `instanceSchema` (req: нет обязательных) | 200 |
| GET | `/typebot/fetchSessions/:typebotId/:instanceName` | yes | query/path | `instanceSchema` (req: нет обязательных) | 200 |
| GET | `/typebot/fetchSettings/:instanceName` | yes | query/path | `instanceSchema` (req: нет обязательных) | 200 |
| GET | `/typebot/find/:instanceName` | yes | query/path | `instanceSchema` (req: нет обязательных) | 200 |
| POST | `/typebot/ignoreJid/:instanceName` | yes | json | `typebotIgnoreJidSchema` (req: remoteJid, action) | 200 |
| POST | `/typebot/settings/:instanceName` | yes | json | `typebotSettingSchema` (req: expire, keywordFinish, delayMessage, unknownMessage, listeningFromMe, stopBotFromMe) | 200 |
| POST | `/typebot/start/:instanceName` | yes | json | `typebotStartSchema` (req: remoteJid, url, typebot) | 200 |
| PUT | `/typebot/update/:typebotId/:instanceName` | yes | json | `typebotSchema` (req: enabled, url, typebot, triggerType) | 200 |

### openai

| Method | Path | Auth | Content-Type | Schema | Status |
|---|---|---|---|---|---|
| POST | `/openai/changeStatus/:instanceName` | yes | json | `openaiStatusSchema` (req: remoteJid, status) | 200 |
| POST | `/openai/create/:instanceName` | yes | json | `openaiSchema` (req: enabled, openaiCredsId, botType, triggerType) | 201 |
| GET | `/openai/creds/:instanceName` | yes | query/path | `instanceSchema` (req: нет обязательных) | 200 |
| POST | `/openai/creds/:instanceName` | yes | json | `openaiCredsSchema` (req: name, apiKey) | 201 |
| DELETE | `/openai/creds/:openaiCredsId/:instanceName` | yes | json | `instanceSchema` (req: нет обязательных) | 200 |
| DELETE | `/openai/delete/:openaiBotId/:instanceName` | yes | json | `instanceSchema` (req: нет обязательных) | 200 |
| GET | `/openai/fetch/:openaiBotId/:instanceName` | yes | query/path | `instanceSchema` (req: нет обязательных) | 200 |
| GET | `/openai/fetchSessions/:openaiBotId/:instanceName` | yes | query/path | `instanceSchema` (req: нет обязательных) | 200 |
| GET | `/openai/fetchSettings/:instanceName` | yes | query/path | `instanceSchema` (req: нет обязательных) | 200 |
| GET | `/openai/find/:instanceName` | yes | query/path | `instanceSchema` (req: нет обязательных) | 200 |
| GET | `/openai/getModels/:instanceName` | yes | query/path | `instanceSchema` (req: нет обязательных) | 200 |
| POST | `/openai/ignoreJid/:instanceName` | yes | json | `openaiIgnoreJidSchema` (req: remoteJid, action) | 200 |
| POST | `/openai/settings/:instanceName` | yes | json | `openaiSettingSchema` (req: openaiCredsId, expire, keywordFinish, delayMessage, unknownMessage, listeningFromMe, stopBotFromMe, keepOpen, debounceTime, ignoreJids) | 200 |
| PUT | `/openai/update/:openaiBotId/:instanceName` | yes | json | `openaiSchema` (req: enabled, openaiCredsId, botType, triggerType) | 200 |

### dify

| Method | Path | Auth | Content-Type | Schema | Status |
|---|---|---|---|---|---|
| POST | `/dify/changeStatus/:instanceName` | yes | json | `difyStatusSchema` (req: remoteJid, status) | 200 |
| POST | `/dify/create/:instanceName` | yes | json | `difySchema` (req: enabled, botType, triggerType) | 201 |
| DELETE | `/dify/delete/:difyId/:instanceName` | yes | json | `instanceSchema` (req: нет обязательных) | 200 |
| GET | `/dify/fetch/:difyId/:instanceName` | yes | query/path | `instanceSchema` (req: нет обязательных) | 200 |
| GET | `/dify/fetchSessions/:difyId/:instanceName` | yes | query/path | `instanceSchema` (req: нет обязательных) | 200 |
| GET | `/dify/fetchSettings/:instanceName` | yes | query/path | `instanceSchema` (req: нет обязательных) | 200 |
| GET | `/dify/find/:instanceName` | yes | query/path | `instanceSchema` (req: нет обязательных) | 200 |
| POST | `/dify/ignoreJid/:instanceName` | yes | json | `difyIgnoreJidSchema` (req: remoteJid, action) | 200 |
| POST | `/dify/settings/:instanceName` | yes | json | `difySettingSchema` (req: expire, keywordFinish, delayMessage, unknownMessage, listeningFromMe, stopBotFromMe, keepOpen, debounceTime, ignoreJids, splitMessages, timePerChar) | 200 |
| PUT | `/dify/update/:difyId/:instanceName` | yes | json | `difySchema` (req: enabled, botType, triggerType) | 200 |

### flowise

| Method | Path | Auth | Content-Type | Schema | Status |
|---|---|---|---|---|---|
| POST | `/flowise/changeStatus/:instanceName` | yes | json | `flowiseStatusSchema` (req: remoteJid, status) | 200 |
| POST | `/flowise/create/:instanceName` | yes | json | `flowiseSchema` (req: enabled, apiUrl, triggerType) | 201 |
| DELETE | `/flowise/delete/:flowiseId/:instanceName` | yes | json | `instanceSchema` (req: нет обязательных) | 200 |
| GET | `/flowise/fetch/:flowiseId/:instanceName` | yes | query/path | `instanceSchema` (req: нет обязательных) | 200 |
| GET | `/flowise/fetchSessions/:flowiseId/:instanceName` | yes | query/path | `instanceSchema` (req: нет обязательных) | 200 |
| GET | `/flowise/fetchSettings/:instanceName` | yes | query/path | `instanceSchema` (req: нет обязательных) | 200 |
| GET | `/flowise/find/:instanceName` | yes | query/path | `instanceSchema` (req: нет обязательных) | 200 |
| POST | `/flowise/ignoreJid/:instanceName` | yes | json | `flowiseIgnoreJidSchema` (req: remoteJid, action) | 200 |
| POST | `/flowise/settings/:instanceName` | yes | json | `flowiseSettingSchema` (req: expire, keywordFinish, delayMessage, unknownMessage, listeningFromMe, stopBotFromMe, keepOpen, debounceTime, ignoreJids) | 200 |
| PUT | `/flowise/update/:flowiseId/:instanceName` | yes | json | `flowiseSchema` (req: enabled, apiUrl, triggerType) | 200 |

### n8n

| Method | Path | Auth | Content-Type | Schema | Status |
|---|---|---|---|---|---|
| POST | `/n8n/changeStatus/:instanceName` | yes | json | `n8nStatusSchema` (req: remoteJid, status) | 200 |
| POST | `/n8n/create/:instanceName` | yes | json | `n8nSchema` (req: enabled, webhookUrl, triggerType) | 201 |
| DELETE | `/n8n/delete/:n8nId/:instanceName` | yes | json | `instanceSchema` (req: нет обязательных) | 200 |
| GET | `/n8n/fetch/:n8nId/:instanceName` | yes | query/path | `instanceSchema` (req: нет обязательных) | 200 |
| GET | `/n8n/fetchSessions/:n8nId/:instanceName` | yes | query/path | `instanceSchema` (req: нет обязательных) | 200 |
| GET | `/n8n/fetchSettings/:instanceName` | yes | query/path | `instanceSchema` (req: нет обязательных) | 200 |
| GET | `/n8n/find/:instanceName` | yes | query/path | `instanceSchema` (req: нет обязательных) | 200 |
| POST | `/n8n/ignoreJid/:instanceName` | yes | json | `n8nIgnoreJidSchema` (req: remoteJid, action) | 200 |
| POST | `/n8n/settings/:instanceName` | yes | json | `n8nSettingSchema` (req: expire, keywordFinish, delayMessage, unknownMessage, listeningFromMe, stopBotFromMe, keepOpen, debounceTime, ignoreJids, splitMessages, timePerChar) | 200 |
| PUT | `/n8n/update/:n8nId/:instanceName` | yes | json | `n8nSchema` (req: enabled, webhookUrl, triggerType) | 200 |

### evoai

| Method | Path | Auth | Content-Type | Schema | Status |
|---|---|---|---|---|---|
| POST | `/evoai/changeStatus/:instanceName` | yes | json | `evoaiStatusSchema` (req: remoteJid, status) | 200 |
| POST | `/evoai/create/:instanceName` | yes | json | `evoaiSchema` (req: enabled, agentUrl, triggerType) | 201 |
| DELETE | `/evoai/delete/:evoaiId/:instanceName` | yes | json | `instanceSchema` (req: нет обязательных) | 200 |
| GET | `/evoai/fetch/:evoaiId/:instanceName` | yes | query/path | `instanceSchema` (req: нет обязательных) | 200 |
| GET | `/evoai/fetchSessions/:evoaiId/:instanceName` | yes | query/path | `instanceSchema` (req: нет обязательных) | 200 |
| GET | `/evoai/fetchSettings/:instanceName` | yes | query/path | `instanceSchema` (req: нет обязательных) | 200 |
| GET | `/evoai/find/:instanceName` | yes | query/path | `instanceSchema` (req: нет обязательных) | 200 |
| POST | `/evoai/ignoreJid/:instanceName` | yes | json | `evoaiIgnoreJidSchema` (req: remoteJid, action) | 200 |
| POST | `/evoai/settings/:instanceName` | yes | json | `evoaiSettingSchema` (req: expire, keywordFinish, delayMessage, unknownMessage, listeningFromMe, stopBotFromMe, keepOpen, debounceTime, ignoreJids, splitMessages, timePerChar) | 200 |
| PUT | `/evoai/update/:evoaiId/:instanceName` | yes | json | `evoaiSchema` (req: enabled, agentUrl, triggerType) | 200 |

### evolutionBot

| Method | Path | Auth | Content-Type | Schema | Status |
|---|---|---|---|---|---|
| POST | `/evolutionBot/changeStatus/:instanceName` | yes | json | `evolutionBotStatusSchema` (req: remoteJid, status) | 200 |
| POST | `/evolutionBot/create/:instanceName` | yes | json | `evolutionBotSchema` (req: enabled, apiUrl, triggerType) | 201 |
| DELETE | `/evolutionBot/delete/:evolutionBotId/:instanceName` | yes | json | `instanceSchema` (req: нет обязательных) | 200 |
| GET | `/evolutionBot/fetch/:evolutionBotId/:instanceName` | yes | query/path | `instanceSchema` (req: нет обязательных) | 200 |
| GET | `/evolutionBot/fetchSessions/:evolutionBotId/:instanceName` | yes | query/path | `instanceSchema` (req: нет обязательных) | 200 |
| GET | `/evolutionBot/fetchSettings/:instanceName` | yes | query/path | `instanceSchema` (req: нет обязательных) | 200 |
| GET | `/evolutionBot/find/:instanceName` | yes | query/path | `instanceSchema` (req: нет обязательных) | 200 |
| POST | `/evolutionBot/ignoreJid/:instanceName` | yes | json | `evolutionBotIgnoreJidSchema` (req: remoteJid, action) | 200 |
| POST | `/evolutionBot/settings/:instanceName` | yes | json | `evolutionBotSettingSchema` (req: expire, keywordFinish, delayMessage, unknownMessage, listeningFromMe, stopBotFromMe, keepOpen, debounceTime, ignoreJids, splitMessages, timePerChar) | 200 |
| PUT | `/evolutionBot/update/:evolutionBotId/:instanceName` | yes | json | `evolutionBotSchema` (req: enabled, apiUrl, triggerType) | 200 |

### s3

| Method | Path | Auth | Content-Type | Schema | Status |
|---|---|---|---|---|---|
| POST | `/s3/getMedia/:instanceName` | yes | json | `s3Schema` (req: нет обязательных) | 201 |
| POST | `/s3/getMediaUrl/:instanceName` | yes | json | `s3UrlSchema` (req: id) | 200 |

### metrics

| Method | Path | Auth | Content-Type | Schema | Status |
|---|---|---|---|---|---|
| GET | `/metrics` | no | — | — | 200, 401, 403, 500 |

### assets

| Method | Path | Auth | Content-Type | Schema | Status |
|---|---|---|---|---|---|
| GET | `/assets/*` | no | — | — | 200, 403, 404 |

### verify-creds

| Method | Path | Auth | Content-Type | Schema | Status |
|---|---|---|---|---|---|
| POST | `/verify-creds` | yes | json | — | 200 |

## Краткие заметки по payload

- `instanceSchema` очень широкая: используется и для создания instance, и для ряда GET/интеграций. В реальных запросах отправляйте только нужные поля под конкретный endpoint.
- `groupValidate`: для group-методов `groupJid` можно передавать в query или body; если без `@g.us`, суффикс добавится автоматически.
- `inviteCodeValidate`: `inviteCode` должен приходить через query (`?inviteCode=...`).
- `getParticipantsValidate`: ожидается query-параметр `getParticipants`.
- Для `chat/findChatByRemoteJid/:instanceName` обязателен query-параметр `remoteJid`.
- Маршруты webhooks без auth: `/webhook/evolution`, `/webhook/meta`, `/chatwoot/webhook/:instanceName`.
- `/metrics` регистрируется только при `PROMETHEUS_METRICS=true`; опционально ограничивается IP и/или Basic Auth.

## Где смотреть детали схем

- Core схемы: `src/validate/*.schema.ts`
- Chatbot схемы: `src/api/integrations/chatbot/**/validate/*.schema.ts`
- Event схемы: `src/api/integrations/event/**/*.schema.ts`
- Storage схемы: `src/api/integrations/storage/**/validate/*.schema.ts`

## Источники в коде

- Маршруты: `src/api/routes/*.router.ts`, `src/api/integrations/**/**/*.router.ts`
- Guards: `src/api/guards/auth.guard.ts`, `src/api/guards/instance.guard.ts`
- Глобальная ошибка: `src/main.ts`
