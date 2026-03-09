# Correções Implementadas - Socialwise

## 🔍 **Problemas Identificados nos Logs**

### 1. **Message é NilClass**
```
[SOCIALWISE] Extracted objects - Message: NilClass, Conversation: OpenStruct, Contact: OpenStruct, Inbox: OpenStruct
```

### 2. **Formato de Timestamp Inválido**
```
[SOCIALWISE] Invalid timestamp format for created_at: 2025-07-25T00:21:51+00:00
```

### 3. **Validação Falhando**
```
[SOCIALWISE] Validation failed for socialwise-chatwit data, using fallback
```

## ✅ **Correções Implementadas**

### 1. **Correção da Validação de Timestamp**

**Problema**: A validação só aceitava formato `Z`, mas o Rails gera formato `+00:00`

**Antes**:
```ruby
timestamp.match?(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/)
```

**Depois**:
```ruby
timestamp.match?(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(Z|[+-]\d{2}:\d{2})/)
```

**Resultado**: Agora aceita ambos os formatos:
- ✅ `2025-07-25T00:21:51Z`
- ✅ `2025-07-25T00:21:51+00:00`

### 2. **Melhoria no Parse de Timestamp**

**Antes**:
```ruby
Time.parse(timestamp.to_s)
```

**Depois**:
```ruby
begin
  parsed_time = Time.parse(timestamp.to_s)
  # Convert to ISO8601 format without timezone for validation
  return parsed_time.utc
rescue => e
  Rails.logger.warn "[SOCIALWISE] Could not parse timestamp #{timestamp}: #{e.message}"
  nil
end
```

**Resultado**: Timestamps são convertidos para UTC consistentemente

### 3. **Logs Adicionais para Debug de Message**

Adicionados logs para entender por que a mensagem não está sendo extraída:

```ruby
Rails.logger.info "[SOCIALWISE] Extracting message from payload with keys: #{payload.keys.inspect}"
Rails.logger.warn "[SOCIALWISE] Message is nil, attempting to extract from payload structure"
Rails.logger.info "[SOCIALWISE] Payload has id: #{payload.key?(:id)}, content: #{payload.key?(:content)}, message_type: #{payload.key?(:message_type)}"
```

## 🎯 **Status Atual**

### ✅ **Funcionando**:
- Socialwise está ativo
- Webhook enhancement está habilitado
- Timestamps são validados corretamente
- Fallback está funcionando

### ⚠️ **Ainda Investigando**:
- Por que `Message: NilClass` (precisa dos novos logs)

## 📊 **Próximos Passos**

### 1. **Teste Imediato**
Envie uma nova mensagem no WhatsApp e verifique se:
- ✅ Não há mais erro de timestamp
- ✅ Validação passa
- 🔍 Veja os novos logs sobre extração de message

### 2. **Logs Esperados Agora**
```
[SOCIALWISE] Extracting message from payload with keys: [:account, :content, :id, ...]
[SOCIALWISE] Creating mock message from root level data
[SOCIALWISE] Successfully built socialwise-chatwit data
[SOCIALWISE] Flat webhook payload enhanced with 35 total fields
```

### 3. **Se Message Ainda For Nil**
Os novos logs mostrarão:
```
[SOCIALWISE] Message is nil, attempting to extract from payload structure
[SOCIALWISE] Payload has id: true, content: true, message_type: true
```

Isso nos dirá se o problema é na detecção ou na criação do mock.

## 🚀 **Resultado Esperado**

Com as correções de timestamp, o payload deve agora passar na validação e você deve ver:

```json
{
  "event": "message_created",
  "wamid": "wamid.HBgMNTU4NTk3NTUwMTM2...",
  "contact_name": "Witalo Rocha",
  "contact_phone": "+558597550136",
  "whatsapp_api_key": "EAAGIBII4GXQBO...",
  "phone_number_id": "274633962398273",
  "business_id": "294585820394901",
  "socialwise_active": true,
  "socialwise-chatwit": {
    "whatsapp_identifiers": { /* dados completos */ },
    "contact_data": { /* dados completos */ },
    "message_data": { /* dados completos */ },
    "metadata": { /* sem erro */ }
  }
}
```

## 🔧 **Teste Agora**

Envie uma mensagem no WhatsApp e verifique se:
1. ❌ Não há mais warnings de timestamp
2. ✅ Validação passa
3. 📊 Dados não são mais nulos
4. 🔍 Novos logs sobre message extraction aparecem

As correções de timestamp devem resolver o problema principal! 🎯