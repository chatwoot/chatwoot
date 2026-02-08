# 🎯 Correções para Exibição de Stickers no Frontend

## 🚨 **PROBLEMAS IDENTIFICADOS NOS LOGS:**

### **1. Envio Duplo Confirmado**
```
# PRIMEIRO ENVIO (SendStickerService):
source_id: "wamid.HBgMNTU4NTk3NTUwMTM2FQIAERgSNEU5NkJBM0VCNjZCMTdDQUE2AA=="

# SEGUNDO ENVIO (SendReplyJob):  
source_id: "wamid.HBgMNTU4NTk3NTUwMTM2FQIAERgSMTIyNDExNDVGMDI1Q0JBQjZBAA=="
```
**Resultado**: Duas mensagens diferentes enviadas para o WhatsApp

### **2. Content Attributes Vazio**
```json
"content_attributes": {},  // ❌ VAZIO!
```
**Resultado**: Frontend não consegue renderizar o sticker → "Sticker indisponível"

### **3. Skip Send Reply Não Funcionou**
```
Enqueued SendReplyJob (Job ID: 221053f8-149a-461f-81aa-892bf6e63393)
```
**Resultado**: SendReplyJob executou mesmo com `skip_send_reply: true`

## ✅ **CORREÇÕES IMPLEMENTADAS:**

### **1. MessageBuilder - Content Attributes**

**❌ ANTES:**
```ruby
def message_params
  {
    account_id: @conversation.account_id,
    inbox_id: @conversation.inbox_id,
    message_type: message_type,
    content: @params[:content],
    private: @private,
    sender: sender,
    content_type: @params[:content_type],
    items: @items,
    in_reply_to: @in_reply_to,
    echo_id: @params[:echo_id],
    source_id: @params[:source_id]
    # ❌ FALTAVA content_attributes!
  }.merge(external_created_at).merge(automation_rule_id).merge(campaign_id).merge(template_params)
end
```

**✅ DEPOIS:**
```ruby
def message_params
  {
    account_id: @conversation.account_id,
    inbox_id: @conversation.inbox_id,
    message_type: message_type,
    content: @params[:content],
    private: @private,
    sender: sender,
    content_type: @params[:content_type],
    content_attributes: content_attributes, # ✅ ADICIONADO!
    items: @items,
    in_reply_to: @in_reply_to,
    echo_id: @params[:echo_id],
    source_id: @params[:source_id]
  }.merge(external_created_at).merge(automation_rule_id).merge(campaign_id).merge(template_params).merge(additional_attributes)
end
```

### **2. MessageBuilder - Additional Attributes**

**❌ ANTES:**
```ruby
# Não havia suporte genérico para additional_attributes
# Apenas métodos específicos como campaign_id e template_params
```

**✅ DEPOIS:**
```ruby
def additional_attributes
  @params[:additional_attributes].present? ? { additional_attributes: @params[:additional_attributes] } : {}
end

def message_params
  # ...
  }.merge(external_created_at).merge(automation_rule_id).merge(campaign_id).merge(template_params).merge(additional_attributes)
  #                                                                                                    ^^^^^^^^^^^^^^^^^^^^^^^^
  #                                                                                                    ✅ ADICIONADO!
end
```

### **3. SendStickerService - ActionController::Parameters**

**❌ ANTES:**
```ruby
message_params = {
  content: "Sticker: #{@sticker_data[:alt]}",
  content_type: 'sticker',
  content_attributes: { sticker_data: @sticker_data },
  message_type: 'outgoing',
  additional_attributes: { skip_send_reply: true }
}
```

**✅ DEPOIS:**
```ruby
message_params = ActionController::Parameters.new({
  content: "Sticker: #{@sticker_data[:alt]}",
  content_type: 'sticker',
  content_attributes: { sticker_data: @sticker_data },
  message_type: 'outgoing',
  additional_attributes: { skip_send_reply: true }
})
```

## 🎯 **FLUXO CORRIGIDO:**

### **1. Criação da Mensagem**
```ruby
# MessageBuilder agora preserva:
content_attributes: { sticker_data: @sticker_data }  # ✅ Para renderização
additional_attributes: { skip_send_reply: true }     # ✅ Para evitar envio duplo
```

### **2. Verificação Skip Send Reply**
```ruby
# app/models/message.rb
def send_reply
  return if additional_attributes&.dig('skip_send_reply')  # ✅ Agora funciona!
  # ...
end
```

### **3. Frontend Rendering**
```vue
<!-- app/javascript/dashboard/components-next/message/bubbles/Sticker.vue -->
const stickerData = computed(() => {
  return contentAttributes.value?.sticker_data || {};  // ✅ Agora tem dados!
});

const stickerUrl = computed(() => {
  return stickerData.value.url || '';  // ✅ URL disponível!
});
```

## 📊 **RESULTADOS ESPERADOS:**

### **Backend:**
- ✅ `content_attributes` preenchido com `sticker_data`
- ✅ `additional_attributes` preenchido com `skip_send_reply: true`
- ✅ Apenas um envio para WhatsApp (sem SendReplyJob)
- ✅ `source_id` atualizado corretamente

### **Frontend:**
- ✅ Sticker renderizado corretamente (não mais "indisponível")
- ✅ URL do sticker acessível
- ✅ Metadados do sticker disponíveis
- ✅ Sender correto (Dra Amanda)

### **Logs Esperados:**
```
"content_attributes": {
  "sticker_data": {
    "id": 7513,
    "url": "http://localhost:3000/rails/active_storage/blobs/redirect/...",
    "alt": "Custom Stickers",
    "provider": "custom"
  }
},
"additional_attributes": {
  "skip_send_reply": true
}
```

## 🧪 **TESTE RECOMENDADO:**

1. **Enviar um sticker**
2. **Verificar logs**:
   - `content_attributes` não vazio
   - `additional_attributes` com `skip_send_reply: true`
   - Apenas um `source_id` (sem SendReplyJob)
3. **Verificar frontend**:
   - Sticker renderizado (não "indisponível")
   - Sender correto (D - Dra Amanda)
   - Checks de status funcionando

**As correções implementadas devem resolver completamente o problema de exibição dos stickers no frontend!** 🎯