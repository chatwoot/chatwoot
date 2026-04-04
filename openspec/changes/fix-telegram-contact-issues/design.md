## Context

Quando um usuário envia mensagem pelo Telegram, o `Telegram::IncomingMessageService` cria um contato via `ContactInboxWithContactBuilder`. Atualmente:

- O `name` do contato é `"#{first_name} #{last_name}"` sem fallback — usuários que só têm username ficam com nome `" "` (espaço)
- O `identifier` não é preenchido — sem deduplicação por ID Telegram e sem busca por esse campo
- O `Contacts::ContactableInboxesService` não possui case para `Channel::Telegram` — o inbox Telegram nunca aparece como opção ao iniciar nova conversa a partir de Contacts
- A query de busca de contatos não inclui `additional_attributes->>'social_telegram_user_name'`

## Goals / Non-Goals

**Goals:**
- Preencher `identifier` com o Telegram `from_id` ao criar/encontrar contato
- Usar `@username` como fallback de `name` quando first/last name estiverem ausentes
- Expor `Channel::Telegram` no `ContactableInboxesService` usando o `source_id` do `contact_inbox` existente
- Incluir `social_telegram_user_name` na query de busca de contatos

**Non-Goals:**
- Migration retroativa de contatos Telegram existentes
- Atualização de `identifier` em contatos já criados
- Suporte a grupos Telegram (já bloqueado pelo `private_message?` check)

## Decisions

### D1 — `identifier` = `telegram_from_id.to_s`

O `from_id` é o ID numérico único do usuário no Telegram. É estável, não muda quando o usuário troca username. Usar como `identifier` garante:
- Deduplicação via `find_contact_by_identifier` no `ContactInboxWithContactBuilder`
- Busca via campo `identifier` já presente na query do `contacts_controller`

Alternativa considerada: usar `username` — descartado pois o username pode mudar.

### D2 — Fallback de name via `.strip.presence || "@#{username}"`

O `strip.presence` retorna `nil` quando o resultado é string vazia ou só espaços. Nesse caso, usa-se `@username`. Se o username também for `nil` (raro mas possível em bots), o `Haikunator` no `create_contact` do builder já garante um nome gerado.

### D3 — `telegram_contactable_inbox` busca o `contact_inbox` existente

Para Telegram não é possível derivar o `source_id` de atributos do contato (como email/telefone para outros canais). O `source_id` correto é o `chat_id` do Telegram, que já está salvo no `contact_inbox`. A implementação busca o `contact_inbox` mais recente para aquele contato naquele inbox e retorna seu `source_id`.

### D4 — Busca inclui `additional_attributes->>'social_telegram_user_name'`

Sintaxe PostgreSQL JSONB. Permite encontrar contatos buscando pelo username Telegram mesmo que o `name` seja diferente.

## Risks / Trade-offs

- **Identifier collision**: Se dois canais diferentes usarem o mesmo `identifier` para contatos distintos (improvável mas possível em accounts com múltiplos canais Telegram). Mitigação: o `identifier` é scoped por `account_id` no model, e cada canal Telegram tem seu próprio `contact_inbox`.
- **Usuários sem username e sem nome**: Ficam com `name` gerado pelo Haikunator — comportamento já existente, não piorado.
- **Contatos legados**: Contatos criados antes desta mudança não terão `identifier` preenchido. A deduplicação por `source_id` no `contact_inbox` continua funcionando para eles normalmente.

## Migration Plan

Nenhuma migration necessária. As mudanças são aplicadas apenas em novas interações Telegram. Deploy direto sem rollback especial.
