# 🔧 Correção: Processamento de Resposta Instagram do SocialWise Flow

## 🚨 Problema Identificado

O fluxo do Chatwoot não conseguia processar respostas do SocialWise Flow para Instagram devido a **incompatibilidade na estrutura do payload**.

### Log do Erro
```
[SocialwiseFlowWebhook] INFO: 🎯 FINAL WEBHOOK RESPONSE {
  finalResponse: '{
    "instagram": {
      "message_format": "BUTTON_TEMPLATE",
      "message": {
        "attachment": {
          "type": "template",
          "payload": {
            "template_type": "button",
            "text": "Como posso ajudar você hoje?",
            "buttons": [...]
          }
        }
      }
    }
  }'
}
```

## 🔍 Análise da Causa Raiz

### Estrutura Enviada pelo SocialWise Flow:
```json
{
  "instagram": {
    "message_format": "BUTTON_TEMPLATE",
    "message": {
      "attachment": {
        "type": "template", 
        "payload": {
          "template_type": "button",
          "text": "Como posso ajudar você hoje?",
          "buttons": [...]
        }
      }
    }
  }
}
```

### Estrutura Esperada pelo InstagramResponseProcessor:
```json
{
  "message_format": "BUTTON_TEMPLATE",
  "payload": {
    "template_type": "button",
    "text": "Como posso ajudar você hoje?", 
    "buttons": [...]
  }
}
```

## ⚡ Problema Principal

O `InstagramResponseProcessor` foi originalmente desenvolvido para processar payloads do **Dialogflow** (formato normalizado), mas o **SocialWise Flow** envia payloads com estrutura aninhada diferente:

- **SocialWise Flow**: `instagram.message.attachment.payload`
- **Dialogflow**: `payload` (direto)

## 🔧 Solução Implementada

### 1. Método de Normalização

Adicionado método `normalize_socialwise_flow_instagram_payload()` em `lib/integrations/socialwise_flow/processor_service.rb`:

```ruby
def normalize_socialwise_flow_instagram_payload(instagram_payload)
  Rails.logger.info "[SOCIALWISE-FLOW][INSTAGRAM] === NORMALIZING SOCIALWISE FLOW PAYLOAD ==="
  
  begin
    # Verificar se já está no formato correto (Dialogflow)
    if instagram_payload['payload'].present? && instagram_payload['message_format'].present?
      Rails.logger.info "[SOCIALWISE-FLOW][INSTAGRAM] Payload already in Dialogflow format"
      return instagram_payload
    end
    
    # Verificar se é formato SocialWise Flow com estrutura aninhada
    if instagram_payload['message'].present? && 
       instagram_payload['message']['attachment'].present? && 
       instagram_payload['message']['attachment']['payload'].present?
      
      Rails.logger.info "[SOCIALWISE-FLOW][INSTAGRAM] Detected SocialWise Flow nested format"
      
      message_format = instagram_payload['message_format']
      nested_payload = instagram_payload['message']['attachment']['payload']
      
      normalized = {
        'message_format' => message_format,
        'payload' => nested_payload
      }
      
      Rails.logger.info "[SOCIALWISE-FLOW][INSTAGRAM] Normalized payload: #{normalized.inspect}"
      return normalized
    end
    
    # Outros formatos...
    
  rescue StandardError => e
    Rails.logger.error "[SOCIALWISE-FLOW][INSTAGRAM] Payload normalization failed: #{e.class}: #{e.message}"
    return nil
  end
end
```

### 2. Modificação no process_instagram_response

Atualizado o método `process_instagram_response()` para usar a normalização:

```ruby
def process_instagram_response(message, instagram_payload)
  # ... validações ...
  
  # CORREÇÃO: Reestruturar payload do SocialWise Flow para formato esperado
  normalized_payload = normalize_socialwise_flow_instagram_payload(instagram_payload)
  
  if normalized_payload.nil?
    Rails.logger.error "[SOCIALWISE-FLOW][INSTAGRAM] Failed to normalize Instagram payload structure"
    create_fallback_instagram_message(message, instagram_payload)
    return
  end
  
  Rails.logger.info "[SOCIALWISE-FLOW][INSTAGRAM] Payload normalized successfully"
  
  # Usar o InstagramResponseProcessor com payload normalizado
  success = Integrations::Socialwise::InstagramResponseProcessor.process(normalized_payload, message)
  
  # ... resto do processamento ...
end
```

## ✅ Validação da Correção

### Teste Executado:
```bash
ruby test_socialwise_flow_instagram_fix.rb
```

### Resultado:
```
✅ SUCESSO: Payload normalizado está correto e compatível com InstagramResponseProcessor
✅ O InstagramResponseProcessor agora conseguirá processar a resposta

📋 RESUMO DA CORREÇÃO:
   1. ✅ Identificado problema: estrutura de payload incompatível
   2. ✅ Implementado método normalize_socialwise_flow_instagram_payload
   3. ✅ Payload SocialWise Flow convertido para formato Dialogflow
   4. ✅ InstagramResponseProcessor agora pode processar corretamente
```

## 🎯 Fluxo Corrigido

1. **SocialWise Flow** envia resposta com payload aninhado
2. **process_instagram_response** recebe o payload
3. **normalize_socialwise_flow_instagram_payload** converte para formato Dialogflow
4. **InstagramResponseProcessor** processa o payload normalizado com sucesso
5. **Mensagem rica** é criada corretamente no dashboard

## 📁 Arquivos Modificados

- `lib/integrations/socialwise_flow/processor_service.rb`
  - ✅ Adicionado `normalize_socialwise_flow_instagram_payload()`
  - ✅ Modificado `process_instagram_response()` para usar normalização
  - ✅ Mantido fallback para casos de erro

## 🔄 Compatibilidade

A solução mantém **compatibilidade total** com:
- ✅ Payloads do Dialogflow (formato original)
- ✅ Payloads do SocialWise Flow (formato aninhado)
- ✅ Payloads diretos (sem aninhamento)
- ✅ Fallback para mensagens de texto em caso de erro

## 🚀 Resultado

**O fluxo do Chatwoot agora consegue processar corretamente as respostas do SocialWise Flow para Instagram**, convertendo automaticamente a estrutura do payload para o formato esperado pelo `InstagramResponseProcessor`.

---

**Status**: ✅ **RESOLVIDO**  
**Data**: 31/01/2025  
**Impacto**: Crítico - Funcionalidade Instagram do SocialWise Flow restaurada