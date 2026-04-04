## 1. Fix Telegram Contact Creation

- [x] 1.1 Em `app/services/telegram/incoming_message_service.rb`, adicionar `identifier: telegram_params_from_id.to_s` ao método `contact_attributes`
- [x] 1.2 Em `app/services/telegram/incoming_message_service.rb`, alterar o `name` no método `contact_attributes` para usar fallback: `"#{telegram_params_first_name} #{telegram_params_last_name}".strip.presence || "@#{telegram_params_username}"`

## 2. Fix ContactableInboxesService para Telegram

- [x] 2.1 Em `app/services/contacts/contactable_inboxes_service.rb`, adicionar case `when 'Channel::Telegram'` no método `get_contactable_inbox` chamando `telegram_contactable_inbox(inbox)`
- [x] 2.2 Em `app/services/contacts/contactable_inboxes_service.rb`, implementar o método privado `telegram_contactable_inbox(inbox)` que busca o `contact_inbox` mais recente do contato naquele inbox e retorna `{ source_id: contact_inbox.source_id, inbox: inbox }`

## 3. Fix Busca de Contatos

- [x] 3.1 Em `app/controllers/api/v1/accounts/contacts_controller.rb`, no método `search`, adicionar `OR contacts.additional_attributes->>'social_telegram_user_name' ILIKE :search` à query de busca

## 5. Fix chat_id vazio ao enviar por Contacts

- [x] 5.1 Em `app/models/channel/telegram.rb`, fazer `chat_id` usar `contact_inbox.source_id` quando `additional_attributes['chat_id']` estiver ausente (conversas criadas pelo fluxo de Contacts)
- [x] 5.2 Em `composeConversationHelper.js`, `processContactableInboxes` deve mapear `source_id` (snake_case dos `contact_inboxes` embutidos no contact) além de `sourceId` — sem isso, na página de Contatos o `source_id` ia vazio no POST de conversa
- [x] 5.3 Fallback extra em `chat_id`: `social_telegram_user_id` / `identifier` no contato; `telegram_contactable_inbox` só retorna inbox se `source_id` estiver presente

## 4. Testes

- [x] 4.1 Verificar que novo contato Telegram criado após deploy tem `identifier` preenchido com o Telegram ID
- [x] 4.2 Verificar que contato com username mas sem nome aparece com `@username` na listagem
- [x] 4.3 Verificar que o inbox Telegram aparece nas opções ao iniciar conversa a partir de Contacts
- [x] 4.4 Verificar que busca por username Telegram retorna o contato correto
