# Revisão dos Formatos de Mensagens Ricas - SocialWise Instagram

## Status da Implementação

✅ **GENERIC_TEMPLATE** - TESTADO E FUNCIONANDO
✅ **BUTTON_TEMPLATE** - REVISADO E CORRETO  
✅ **QUICK_REPLIES** - REVISADO E CORRETO

## Detalhes da Revisão

### 1. GENERIC_TEMPLATE ✅
**Status**: Testado pelo usuário e funcionando perfeitamente

**Estrutura Esperada**:
```json
{
  "socialwiseResponse": {
    "message_format": "GENERIC_TEMPLATE",
    "payload": {
      "template_type": "generic",
      "elements": [
        {
          "title": "Dra. Amanda Sousa Advocacia",
          "subtitle": "Selecione uma das opções abaixo.",
          "image_url": "https://url.da.sua.imagem/aqui.png",
          "buttons": [
            { "type": "postback", "title": "Ver Serviços", "payload": "ver_servicos" },
            { "type": "web_url", "url": "https://seusite.com/servicos", "title": "Abrir Site" }
          ]
        }
      ]
    }
  }
}
```

**Resultado Final na API Instagram**:
```json
{
  "recipient": { "id": "<IGSID>" },
  "message": {
    "attachment": {
      "type": "template",
      "payload": {
        "template_type": "generic",
        "elements": [...]
      }
    }
  }
}
```

### 2. BUTTON_TEMPLATE ✅
**Status**: Implementação revisada e correta

**Estrutura Esperada**:
```json
{
  "socialwiseResponse": {
    "message_format": "BUTTON_TEMPLATE",
    "payload": {
      "template_type": "button",
      "text": "Olá! Gostaria de falar com um atendente?",
      "buttons": [
        { "type": "postback", "title": "Falar com Atendente", "payload": "human_handoff" },
        { "type": "web_url", "url": "https://seusite.com/ajuda", "title": "Ver FAQ" }
      ]
    }
  }
}
```

**Resultado Final na API Instagram**:
```json
{
  "recipient": { "id": "<IGSID>" },
  "message": {
    "attachment": {
      "type": "template",
      "payload": {
        "template_type": "button",
        "text": "Olá! Gostaria de falar com um atendente?",
        "buttons": [...]
      }
    }
  }
}
```

**Validações Implementadas**:
- ✅ `template_type` deve ser 'button'
- ✅ `text` deve estar presente e não vazio
- ✅ `buttons` deve ser array com 1-3 botões
- ✅ Cada botão deve ter `type`, `title` e campo específico (`payload` ou `url`)
- ✅ Títulos dos botões limitados a 20 caracteres
- ✅ Payloads limitados a 1000 caracteres
- ✅ URLs validadas e limitadas a 2000 caracteres

### 3. QUICK_REPLIES ✅
**Status**: Implementação revisada e correta

**Estrutura Esperada**:
```json
{
  "socialwiseResponse": {
    "message_format": "QUICK_REPLIES",
    "payload": {
      "text": "Selecione o assunto do seu interesse:",
      "quick_replies": [
        { "content_type": "text", "title": "Serviços", "payload": "ver_servicos" },
        { "content_type": "text", "title": "Endereço", "payload": "ver_endereco" }
      ]
    }
  }
}
```

**Resultado Final na API Instagram**:
```json
{
  "recipient": { "id": "<IGSID>" },
  "messaging_type": "RESPONSE",
  "message": {
    "text": "Selecione o assunto do seu interesse:",
    "quick_replies": [
      { "content_type": "text", "title": "Serviços", "payload": "ver_servicos" },
      { "content_type": "text", "title": "Endereço", "payload": "ver_endereco" }
    ]
  }
}
```

**Validações Implementadas**:
- ✅ `text` deve estar presente e não vazio
- ✅ `quick_replies` deve ser array com 1-13 opções
- ✅ Cada quick reply deve ter `content_type: 'text'`
- ✅ Cada quick reply deve ter `title` e `payload`
- ✅ Títulos limitados a 20 caracteres
- ✅ Payloads limitados a 1000 caracteres
- ✅ `messaging_type: "RESPONSE"` adicionado automaticamente

## Métodos Implementados e Revisados

### InstagramResponseProcessor
- ✅ `validate_button_template(payload)` - Validação completa
- ✅ `validate_quick_replies(payload)` - Validação completa
- ✅ `build_button_template_payload(payload)` - Construção correta
- ✅ `build_quick_replies_payload(payload)` - Construção correta
- ✅ `build_button_template_buttons(buttons)` - Processamento de botões
- ✅ `build_quick_replies_options(quick_replies)` - Processamento de opções
- ✅ `send_button_template(payload, message)` - Envio com flag skip_send_reply
- ✅ `send_quick_replies(payload, message)` - Envio com flag skip_send_reply

### Instagram::RichMessageService
- ✅ `template_format?` - Identifica corretamente generic e button templates
- ✅ `build_button_template` - Constrói estrutura de attachment correta
- ✅ `build_quick_replies_message` - Constrói estrutura de message correta
- ✅ `rich_message_params` - Adiciona `messaging_type: "RESPONSE"` para quick replies

## Correção de Envio Duplo Aplicada

Todos os três formatos agora incluem a flag `skip_send_reply: true` nas mensagens criadas:

```ruby
outgoing_message = conversation.messages.create!(
  content: extract_fallback_text({ 'payload' => payload }),
  message_type: :outgoing,
  account_id: conversation.account_id,
  inbox_id: conversation.inbox_id,
  additional_attributes: { skip_send_reply: true } # ← Previne envio duplo
)
```

## Sistema de Fallback

O método `extract_fallback_text` funciona corretamente para todos os formatos:
- **BUTTON_TEMPLATE**: Usa o campo `text`
- **QUICK_REPLIES**: Usa o campo `text`  
- **GENERIC_TEMPLATE**: Usa o `title` do primeiro elemento
- **Fallback genérico**: "Message received"

## Conclusão

✅ **Todos os três formatos estão implementados corretamente**
✅ **Validações seguem as especificações da Meta/Instagram**
✅ **Estruturas finais estão conforme documentação da API**
✅ **Correção de envio duplo aplicada em todos os formatos**
✅ **Sistema de fallback funciona para todos os casos**

Os formatos **BUTTON_TEMPLATE** e **QUICK_REPLIES** devem funcionar perfeitamente, assim como o **GENERIC_TEMPLATE** que já foi testado com sucesso.