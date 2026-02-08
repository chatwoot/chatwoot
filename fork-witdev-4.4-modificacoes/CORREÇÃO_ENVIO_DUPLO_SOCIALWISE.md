# Correção do Envio Duplo de Mensagens - SocialWise Instagram

## Problema Identificado

O sistema estava enviando mensagens duplicadas no Instagram quando processava respostas ricas do Dialogflow (GENERIC_TEMPLATE, BUTTON_TEMPLATE, QUICK_REPLIES). Isso ocorria porque:

1. **Processo Especializado (CORRETO)**: `InstagramResponseProcessor` criava uma mensagem outgoing e usava `Instagram::RichMessageService` para enviar o template rico
2. **Processo Genérico (DUPLICADO)**: O callback `after_create_commit` da mensagem outgoing automaticamente enfileirava `SendReplyJob`, que enviava o texto de fallback como mensagem simples

## Fluxo do Problema

```
Dialogflow Response (GENERIC_TEMPLATE)
    ↓
InstagramResponseProcessor.process()
    ↓
Cria mensagem outgoing com texto de fallback
    ↓
┌─────────────────────────────────────┬─────────────────────────────────────┐
│ PROCESSO CORRETO                    │ PROCESSO DUPLICADO                  │
│                                     │                                     │
│ Instagram::RichMessageService       │ after_create_commit callback        │
│ ↓                                   │ ↓                                   │
│ Envia template rico via API         │ send_reply()                        │
│ ✅ MENSAGEM RICA ENVIADA           │ ↓                                   │
│                                     │ SendReplyJob.perform_later()        │
│                                     │ ↓                                   │
│                                     │ Instagram::SendOnInstagramService   │
│                                     │ ↓                                   │
│                                     │ ❌ TEXTO SIMPLES ENVIADO           │
└─────────────────────────────────────┴─────────────────────────────────────┘
```

## Solução Implementada

### 1. Flag `skip_send_reply` nas Mensagens

Adicionado um atributo `skip_send_reply` no `additional_attributes` das mensagens criadas especificamente para o `RichMessageService`:

```ruby
outgoing_message = conversation.messages.create!(
  content: extract_fallback_text({ 'payload' => payload }),
  message_type: :outgoing,
  account_id: conversation.account_id,
  inbox_id: conversation.inbox_id,
  additional_attributes: { skip_send_reply: true }  # ← NOVA FLAG
)
```

### 2. Modificação no Método `send_reply`

Atualizado o método `send_reply` no modelo `Message` para verificar a flag:

```ruby
def send_reply
  # Skip sending reply if message is marked to skip (e.g., for rich messages handled by specialized services)
  return if additional_attributes&.dig('skip_send_reply')

  # FIXME: Giving it few seconds for the attachment to be uploaded to the service
  # active storage attaches the file only after commit
  attachments.blank? ? ::SendReplyJob.perform_later(id) : ::SendReplyJob.set(wait: 2.seconds).perform_later(id)
end
```

## Arquivos Modificados

1. **`lib/integrations/socialwise/instagram_response_processor.rb`**

   - Adicionada flag `skip_send_reply: true` em 3 métodos:
     - `send_generic_template`
     - `send_button_template`
     - `send_quick_replies`

2. **`app/models/message.rb`**
   - Modificado método `send_reply` para verificar a flag

## Fluxo Após a Correção

```
Dialogflow Response (GENERIC_TEMPLATE)
    ↓
InstagramResponseProcessor.process()
    ↓
Cria mensagem outgoing com skip_send_reply: true
    ↓
┌─────────────────────────────────────┬─────────────────────────────────────┐
│ PROCESSO CORRETO                    │ PROCESSO PREVENIDO                  │
│                                     │                                     │
│ Instagram::RichMessageService       │ after_create_commit callback        │
│ ↓                                   │ ↓                                   │
│ Envia template rico via API         │ send_reply()                        │
│ ✅ MENSAGEM RICA ENVIADA           │ ↓                                   │
│                                     │ Verifica skip_send_reply flag       │
│                                     │ ↓                                   │
│                                     │ ✅ RETORNA SEM ENVIAR              │
└─────────────────────────────────────┴─────────────────────────────────────┘
```

## Preservação do Sistema de Fallback

A correção **NÃO afeta** o sistema de fallback:

- O método `fallback_to_text_message` continua funcionando normalmente
- Mensagens de fallback são enviadas quando há erros no processamento de mensagens ricas
- Apenas as mensagens criadas especificamente para `RichMessageService` são marcadas com a flag

## Teste da Correção

Criado teste simples que confirma:

- ✅ Mensagens sem flag `skip_send_reply` enfileiram `SendReplyJob` normalmente
- ✅ Mensagens com flag `skip_send_reply` pulam o `SendReplyJob`

## Resultado

- ❌ **ANTES**: 2 mensagens enviadas (template rico + texto simples)
- ✅ **DEPOIS**: 1 mensagem enviada (apenas template rico)

A correção elimina completamente o envio duplo mantendo toda a funcionalidade do sistema de fallback intacta.
