# Implementação de Payload Flat para Webhooks Comuns

## Problema Identificado
Os webhooks comuns estavam recebendo apenas a estrutura aninhada `socialwise-chatwit`, mas com dados vazios devido a incompatibilidade entre o formato `webhook_data` (Hash) e os métodos que esperavam objetos ActiveRecord.

## Solução Implementada

### 1. **Detecção de Formato de Payload**
**Arquivo:** `lib/integrations/socialwise/webhook_enhancer_service.rb`

O serviço agora detecta automaticamente se os dados estão no formato `webhook_data` (Hash) ou como objetos ActiveRecord e cria objetos mock compatíveis:

```ruby
def extract_message_from_payload(payload)
  message = payload[:message] || payload['message']
  
  # If it's a webhook_data format (Hash), convert to a mock object
  if message.is_a?(Hash)
    return create_mock_message_from_webhook_data(message)
  end
  
  message
end
```

### 2. **Objetos Mock para Webhook Data**
Criados métodos para converter dados de webhook em objetos mock que funcionam com a lógica existente:

```ruby
def create_mock_message_from_webhook_data(webhook_data)
  OpenStruct.new(
    id: webhook_data[:id] || webhook_data['id'],
    content: webhook_data[:content] || webhook_data['content'],
    content_type: webhook_data[:content_type] || webhook_data['content_type'],
    message_type: webhook_data[:message_type] || webhook_data['message_type'],
    created_at: parse_timestamp(webhook_data[:created_at] || webhook_data['created_at']),
    source_id: webhook_data[:source_id] || webhook_data['source_id'],
    content_attributes: webhook_data[:content_attributes] || webhook_data['content_attributes'] || {}
  )
end
```

### 3. **Payload Flat para Webhooks**
Adicionado método `add_flat_socialwise_data` que cria campos flat no payload principal, similar ao que é feito para o Dialogflow:

```ruby
def add_flat_socialwise_data(payload, socialwise_data)
  flat_payload = payload.dup
  
  # WhatsApp identifiers
  flat_payload['wamid'] = socialwise_data['whatsapp_identifiers']['wamid']
  flat_payload['contact_source'] = socialwise_data['whatsapp_identifiers']['contact_source']
  
  # Contact data
  flat_payload['contact_name'] = socialwise_data['contact_data']['name']
  flat_payload['contact_phone'] = socialwise_data['contact_data']['phone_number']
  
  # Interactive data (button/list IDs)
  if socialwise_data['message_data']['interactive_data']
    interactive_data = socialwise_data['message_data']['interactive_data']
    flat_payload['button_id'] = interactive_data['button_id']
    flat_payload['button_title'] = interactive_data['button_title']
    flat_payload['list_id'] = interactive_data['list_id']
    flat_payload['list_title'] = interactive_data['list_title']
    flat_payload['interaction_type'] = interactive_data['interaction_type']
  end
  
  # WhatsApp API data
  flat_payload['whatsapp_api_key'] = socialwise_data['whatsapp_api_key']
  flat_payload['phone_number_id'] = socialwise_data['whatsapp_phone_number_id']
  flat_payload['business_id'] = socialwise_data['whatsapp_business_id']
  
  flat_payload
end
```

### 4. **Compatibilidade com Provider Config**
Método `get_provider_config` que funciona tanto com objetos ActiveRecord quanto com objetos mock:

```ruby
def get_provider_config(inbox)
  return nil unless inbox
  
  if inbox.respond_to?(:channel) && inbox.channel.respond_to?(:provider_config)
    inbox.channel.provider_config
  elsif inbox.is_a?(OpenStruct) && inbox.channel.is_a?(OpenStruct)
    inbox.channel.provider_config
  else
    nil
  end
end
```

## Estrutura do Payload Final para Webhooks

### Antes (apenas estrutura aninhada com dados vazios):
```json
{
  "event": "message_created",
  "socialwise-chatwit": {
    "whatsapp_identifiers": {"wamid": null, "whatsapp_id": null, "contact_source": null},
    "contact_data": {"id": null, "name": null, "phone_number": null},
    "message_data": {"id": null, "content": null, "interactive_data": {}},
    "metadata": {"error": "Data collection failed: NoMethodError: undefined method 'id' for an instance of Hash"}
  }
}
```

### Depois (estrutura aninhada + campos flat populados):
```json
{
  "event": "message_created",
  "id": 32027,
  "content": "Confirmar",
  "source_id": "wamid.HBgNNTUyMTk5NjMyMjE5NRUCABIYIEJBOTVGQjE5NTYwNkI5NDYzNDA1MzQ2RDM4ODVGRTk4AA==",
  
  // Campos flat adicionados pelo Socialwise
  "wamid": "wamid.HBgNNTUyMTk5NjMyMjE5NRUCABIYIEJBOTVGQjE5NTYwNkI5NDYzNDA1MzQ2RDM4ODVGRTk4AA==",
  "contact_name": "- LM",
  "contact_phone": "+5521996322195",
  "contact_id": 1873,
  "conversation_id": 1982,
  "conversation_status": "pending",
  "message_id": 32027,
  "message_content": "Confirmar",
  "message_type": "incoming",
  "inbox_id": 4,
  "inbox_name": "WhatsApp - ANA",
  "account_id": 3,
  "account_name": "DraAmandaSousa",
  "whatsapp_api_key": "EAAGIBII4GXQBO2qgvJ2jdcUmgkdqBo5bUKEanJWmCLpcZAsq0Ovpm4JNlrNLeZAv3OYNrdCqqQBAHfEfPFD0FPnZAOQJURB9GKcbjXeDpa83XdAsa3i6fTr23lBFM2LwUZC23xXrZAnB8QjCCFZBxrxlBvzPj8LsejvUjz0C04Q8Jsl8nTGHUd4ZBRPc4NiHFnc",
  "phone_number_id": "123456789",
  "business_id": "987654321",
  "button_id": "btn_confirm_123",
  "button_title": "Confirmar",
  "interaction_type": "button_reply",
  "socialwise_active": true,
  "is_whatsapp_channel": true,
  "has_whatsapp_api_key": true,
  
  // Estrutura aninhada mantida para compatibilidade
  "socialwise-chatwit": {
    "whatsapp_identifiers": {
      "wamid": "wamid.HBgNNTUyMTk5NjMyMjE5NRUCABIYIEJBOTVGQjE5NTYwNkI5NDYzNDA1MzQ2RDM4ODVGRTk4AA==",
      "whatsapp_id": "wamid.HBgNNTUyMTk5NjMyMjE5NRUCABIYIEJBOTVGQjE5NTYwNkI5NDYzNDA1MzQ2RDM4ODVGRTk4AA==",
      "contact_source": null
    },
    "contact_data": {
      "id": 1873,
      "name": "- LM",
      "phone_number": "+5521996322195",
      "email": "",
      "identifier": "",
      "custom_attributes": {}
    },
    "message_data": {
      "id": 32027,
      "content": "Confirmar",
      "content_type": "text",
      "message_type": "incoming",
      "created_at": "2025-07-24T22:03:43Z",
      "interactive_data": {
        "button_id": "btn_confirm_123",
        "button_title": "Confirmar",
        "interaction_type": "button_reply"
      }
    },
    "whatsapp_api_key": "EAAGIBII4GXQBO2qgvJ2jdcUmgkdqBo5bUKEanJWmCLpcZAsq0Ovpm4JNlrNLeZAv3OYNrdCqqQBAHfEfPFD0FPnZAOQJURB9GKcbjXeDpa83XdAsa3i6fTr23lBFM2LwUZC23xXrZAnB8QjCCFZBxrxlBvzPj8LsejvUjz0C04Q8Jsl8nTGHUd4ZBRPc4NiHFnc",
    "whatsapp_phone_number_id": "123456789",
    "whatsapp_business_id": "987654321"
  }
}
```

## Vantagens da Implementação

### 1. **Dupla Compatibilidade**
- ✅ Mantém estrutura aninhada para sistemas que já a utilizam
- ✅ Adiciona campos flat para fácil acesso direto

### 2. **Fácil Consumo nos Webhooks**
```javascript
// Acesso direto aos campos importantes
const buttonId = payload.button_id;
const contactName = payload.contact_name;
const whatsappApiKey = payload.whatsapp_api_key;

// Ou acesso via estrutura aninhada se preferir
const buttonId = payload['socialwise-chatwit'].message_data.interactive_data.button_id;
```

### 3. **Compatibilidade Total**
- ✅ Funciona com Dialogflow (payload flat)
- ✅ Funciona com webhooks comuns (ambos os formatos)
- ✅ Mantém compatibilidade com integrações existentes
- ✅ Tratamento de erros gracioso

### 4. **Logs Detalhados**
- Logs de extração de dados
- Logs de criação de objetos mock
- Logs de enhancement do payload
- Logs de erros com contexto

## Resultado

Agora os webhooks comuns recebem tanto a estrutura aninhada quanto os campos flat, permitindo que sistemas como o Flowise acessem facilmente os dados do WhatsApp, incluindo IDs de botões e informações da API, da mesma forma que funciona no Dialogflow! 🚀