## Why

Usuários que chegam pelo canal Telegram não aparecem corretamente na listagem de contatos e não é possível iniciar uma nova conversa com eles a partir da tela de Contacts, pois o sistema não salva as informações mínimas necessárias para identificação e não expõe o canal Telegram como opção de inbox contactável.

## What Changes

- Salvar o `telegram_from_id` como `identifier` do contato, garantindo deduplicação correta e busca por ID
- Usar o `@username` do Telegram como fallback de `name` quando o usuário não possui first/last name
- Adicionar suporte a `Channel::Telegram` no `ContactableInboxesService`, permitindo iniciar conversas a partir de Contacts
- Incluir `additional_attributes->>'social_telegram_user_name'` na query de busca de contatos

## Capabilities

### New Capabilities

- `telegram-contactable-inbox`: Exposição do inbox Telegram como opção ao iniciar nova conversa a partir de um contato existente

### Modified Capabilities

- `telegram-contact-creation`: Enriquecimento do contato criado via Telegram com `identifier` e `name` fallback corretos
- `contact-search`: Busca de contatos passa a incluir o username do Telegram

## Impact

- `app/services/telegram/incoming_message_service.rb` — método `contact_attributes`
- `app/services/contacts/contactable_inboxes_service.rb` — adição de case `Channel::Telegram`
- `app/controllers/api/v1/accounts/contacts_controller.rb` — query do método `search`
- Sem migrations de banco de dados
- Contatos Telegram já existentes (sem `identifier`) não são retroativamente atualizados — apenas novas interações
