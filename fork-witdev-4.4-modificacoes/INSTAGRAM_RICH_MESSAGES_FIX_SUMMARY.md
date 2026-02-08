# Fix: Instagram Rich Messages no SocialWise Flow

## Problema Identificado

As mensagens ricas do Instagram não estavam sendo exibidas nem enviadas no SocialWise Flow, enquanto funcionavam corretamente no Dialogflow.

### Causa Raiz

O **SocialWise Flow** estava enviando payloads do Instagram em formato diferente do que o `InstagramResponseProcessor` esperava:

**Formato SocialWise Flow (incorreto):**
```json
{
  "instagram": {
    "message_format": "GENERIC_TEMPLATE",
    "template_type": "generic",
    "elements": [...]
  }
}
```

**Formato esperado pelo InstagramResponseProcessor (Dialogflow):**
```json
{
  "message_format": "GENERIC_TEMPLATE",
  "payload": {
    "template_type": "generic",
    "elements": [...]
  }
}
```

## Solução Implementada

### 1. Reestruturação do Payload

Modificado o método `process_instagram_response` em `lib/integrations/socialwise_flow/processor_service.rb` (linha ~675):

```ruby
# Reestruturar payload para formato esperado pelo InstagramResponseProcessor
# O processor espera: { 'message_format' => '...', 'payload' => { ... } }
# Mas SocialWise Flow envia: { 'message_format' => '...', 'template_type' => '...', ... }
restructured_payload = {
  'message_format' => instagram_payload['message_format'],
  'payload' => instagram_payload.except('message_format')
}

Rails.logger.info "[SOCIALWISE-FLOW][INSTAGRAM] Original payload: #{instagram_payload.inspect}"
Rails.logger.info "[SOCIALWISE-FLOW][INSTAGRAM] Restructured payload: #{restructured_payload.inspect}"

# Usar o InstagramResponseProcessor do Socialwise (mesmo usado pelo Dialogflow)
success = Integrations::Socialwise::InstagramResponseProcessor.process(restructured_payload, message)
```

### 2. Compatibilidade Total

O fix garante que:
- ✅ **GENERIC_TEMPLATE** funciona corretamente
- ✅ **BUTTON_TEMPLATE** funciona corretamente  
- ✅ **QUICK_REPLIES** funciona corretamente
- ✅ Fallback funciona se houver erro
- ✅ Compatibilidade total com Dialogflow mantida

### 3. Fluxo Completo

1. **SocialWise Flow** recebe payload do Instagram
2. **Reestruturação** converte para formato compatível
3. **InstagramResponseProcessor** processa mensagem rica
4. **Instagram Rich Message Service** envia para API do Instagram
5. **Dashboard** exibe mensagem rica usando componentes existentes

## Arquivos Modificados

### Código Principal
- `lib/integrations/socialwise_flow/processor_service.rb` - Fix da reestruturação

### Testes Adicionados
- `spec/lib/integrations/socialwise_flow/instagram_payload_restructuring_spec.rb` - Validação do fix
- `test_instagram_socialwise_fix.rb` - Teste manual de validação
- `debug_instagram_socialwise_flow.rb` - Script de debug

## Benefícios

### ✅ Mensagens Ricas Funcionando
- Mensagens ricas do Instagram agora aparecem no dashboard
- Mensagens ricas do Instagram são enviadas corretamente para o cliente
- Todos os 3 formatos suportados (Generic Template, Button Template, Quick Replies)

### ✅ Compatibilidade Mantida
- Dialogflow continua funcionando normalmente
- Mesmo `InstagramResponseProcessor` usado por ambos
- Nenhuma quebra de funcionalidade existente

### ✅ Robustez
- Fallback automático se houver erro
- Logs detalhados para debugging
- Tratamento de exceções completo

## Validação

### Testes Automatizados
```bash
# Executar teste específico do fix
bundle exec rspec spec/lib/integrations/socialwise_flow/instagram_payload_restructuring_spec.rb

# Executar todos os testes do Instagram
bundle exec rspec spec/lib/integrations/socialwise/instagram_response_processor_spec.rb
```

### Teste Manual
1. Configure um bot no SocialWise Flow com mensagens ricas do Instagram
2. Envie uma mensagem que trigger uma resposta rica
3. Verifique se a mensagem aparece corretamente no dashboard
4. Verifique se a mensagem é enviada para o Instagram

## Formatos Suportados

### Generic Template
```json
{
  "instagram": {
    "message_format": "GENERIC_TEMPLATE",
    "template_type": "generic",
    "elements": [
      {
        "title": "Título",
        "subtitle": "Subtítulo",
        "image_url": "https://example.com/image.jpg",
        "buttons": [
          {
            "type": "postback",
            "title": "Botão",
            "payload": "payload_value"
          }
        ]
      }
    ]
  }
}
```

### Button Template
```json
{
  "instagram": {
    "message_format": "BUTTON_TEMPLATE",
    "template_type": "button",
    "text": "Texto da mensagem",
    "buttons": [
      {
        "type": "postback",
        "title": "Botão 1",
        "payload": "payload_1"
      },
      {
        "type": "web_url",
        "title": "Site",
        "url": "https://example.com"
      }
    ]
  }
}
```

### Quick Replies
```json
{
  "instagram": {
    "message_format": "QUICK_REPLIES",
    "text": "Selecione uma opção:",
    "quick_replies": [
      {
        "content_type": "text",
        "title": "Opção 1",
        "payload": "opcao_1"
      },
      {
        "content_type": "text",
        "title": "Opção 2",
        "payload": "opcao_2"
      }
    ]
  }
}
```

## Status

✅ **IMPLEMENTADO E TESTADO**

O fix foi implementado com sucesso e resolve completamente o problema das mensagens ricas do Instagram no SocialWise Flow, mantendo total compatibilidade com o Dialogflow existente.