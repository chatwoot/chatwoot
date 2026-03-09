# Blocked Contacts Early Rejection

## Data: 2026-02-03

## Objetivo

Descartar completamente mensagens de contatos bloqueados na entrada do webhook, antes de salvar qualquer dado no banco de dados. Isso evita:

1. Criacao de mensagens no banco para contatos bloqueados
2. Broadcast via ActionCable
3. Processamento pelo HookJob (SocialWise Flow, etc.)
4. Respostas automaticas do bot

## Comportamento Anterior

Quando um contato bloqueado enviava uma mensagem:
1. Mensagem era criada no banco de dados
2. Broadcast era feito via ActionCable (`message.created`)
3. HookJob processava a mensagem
4. SocialWise Flow enviava para webhook externo
5. Resposta automatica era gerada e enviada

O bloqueio so era verificado na criacao da conversa (`Conversation#determine_conversation_status`), mudando o status para `:resolved`, mas a mensagem ja tinha sido criada.

## Comportamento Atual

Mensagens de contatos bloqueados sao descartadas imediatamente apos identificar o contato, antes de:
- Criar conversa
- Criar mensagem
- Disparar qualquer job ou hook

## Arquivos Modificados

### 1. WhatsApp
**Arquivo:** `app/services/whatsapp/incoming_message_base_service.rb`

```ruby
# Apos set_contact, antes da transaction:
if @contact.blocked?
  Rails.logger.info("[WHATSAPP] Discarding message from blocked contact: #{@contact.id}")
  clear_message_source_id_from_redis
  return
end
```

### 2. Facebook Page
**Arquivo:** `app/builders/messages/facebook/message_builder.rb`

```ruby
# Dentro da transaction, apos build_contact_inbox:
if @contact_inbox.contact.blocked?
  Rails.logger.info("[FACEBOOK] Discarding message from blocked contact: #{@contact_inbox.contact.id}")
  raise ActiveRecord::Rollback
end
```

### 3. Instagram / Messenger
**Arquivo:** `app/services/instagram/base_message_text.rb`

```ruby
# Apos ensure_contact, antes de create_message:
if @contact_inbox&.contact&.blocked?
  Rails.logger.info("[INSTAGRAM] Discarding message from blocked contact: #{@contact_inbox.contact.id}")
  return
end
```

## Logs de Auditoria

Quando uma mensagem e descartada, um log INFO e gerado:

```
[WHATSAPP] Discarding message from blocked contact: 12345
[FACEBOOK] Discarding message from blocked contact: 12345
[INSTAGRAM] Discarding message from blocked contact: 12345
```

## Fluxo de Bloqueio de Contato

Um contato e marcado como `blocked: true` atraves do metodo `Conversation#mute!`:

```ruby
# app/models/concerns/conversation_mute_helpers.rb
def mute!
  return unless contact
  resolved!
  contact.update(blocked: true)
  create_muted_message
end
```

## Consideracoes

1. **Performance:** A verificacao de bloqueio e feita apos identificar o contato, que ja e uma operacao necessaria. Nao ha overhead significativo.

2. **Consistencia:** O contato ainda e criado/atualizado se nao existir. Apenas a mensagem e descartada.

3. **Auditoria:** Os logs permitem rastrear mensagens descartadas de contatos bloqueados.

4. **Reversibilidade:** Se o contato for desbloqueado (`contact.update(blocked: false)`), as mensagens voltam a ser processadas normalmente.
