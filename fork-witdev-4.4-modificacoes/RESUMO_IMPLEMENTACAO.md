# Resumo da Implementação - Adição de phone_number_id e business_id

## Problema Identificado
O payload do Dialogflow estava enviando informações duplicadas (`whatsapp_id` e `wamid` com o mesmo valor) e não incluía campos importantes como `phone_number_id` e `business_id` que são necessários para integração com o WhatsApp Business API.

## Mudanças Implementadas

### 1. Serviço Socialwise WebhookEnhancerService
**Arquivo:** `lib/integrations/socialwise/webhook_enhancer_service.rb`

**Novos métodos adicionados:**
```ruby
# Extract WhatsApp phone number ID from inbox channel
def extract_whatsapp_phone_number_id(inbox)
  return nil unless inbox&.channel_type == 'Channel::Whatsapp'
  
  begin
    phone_number_id = inbox.channel.provider_config&.dig('phone_number_id')
    Rails.logger.info "[SOCIALWISE] WhatsApp phone_number_id extracted: #{phone_number_id.present? ? 'Present' : 'Not found'}"
    phone_number_id
  rescue => e
    Rails.logger.error "[SOCIALWISE] Error extracting WhatsApp phone_number_id: #{e.class}: #{e.message}"
    nil
  end
end

# Extract WhatsApp business account ID from inbox channel
def extract_whatsapp_business_id(inbox)
  return nil unless inbox&.channel_type == 'Channel::Whatsapp'
  
  begin
    business_id = inbox.channel.provider_config&.dig('business_account_id')
    Rails.logger.info "[SOCIALWISE] WhatsApp business_account_id extracted: #{business_id.present? ? 'Present' : 'Not found'}"
    business_id
  rescue => e
    Rails.logger.error "[SOCIALWISE] Error extracting WhatsApp business_account_id: #{e.class}: #{e.message}"
    nil
  end
end
```

**Campos adicionados ao payload:**
- `whatsapp_phone_number_id`: ID do número de telefone do WhatsApp Business
- `whatsapp_business_id`: ID da conta business do WhatsApp

### 2. Serviço Dialogflow ProcessorService
**Arquivo:** `lib/integrations/dialogflow/processor_service.rb`

**Mudanças realizadas:**
1. **Remoção de duplicação:** Removido o campo `whatsapp_id` mantendo apenas `wamid`
2. **Adição de novos campos:** Incluídos `phone_number_id` e `business_id` no payload flat
3. **Mapeamento dos novos campos:**
```ruby
# WhatsApp API key, phone number ID, business ID and metadata
flat_payload['whatsapp_api_key'] = socialwise_data['whatsapp_api_key']
flat_payload['phone_number_id'] = socialwise_data['whatsapp_phone_number_id']
flat_payload['business_id'] = socialwise_data['whatsapp_business_id']
```

### 3. Testes Atualizados
**Arquivos:**
- `spec/lib/integrations/socialwise/webhook_enhancer_service_spec.rb`
- `spec/lib/integrations/dialogflow/processor_service_spec.rb`

**Novos testes adicionados:**
- Validação da presença dos campos `phone_number_id` e `business_id`
- Testes para canais WhatsApp com e sem esses campos configurados
- Validação de tipos de dados para os novos campos

## Estrutura do Payload Final

### Antes (com duplicação):
```json
{
  "wamid": "wamid.HBgNNTUyMTk5NjMyMjE5NRUCABIYIEJBOTVGQjE5NTYwNkI5NDYzNDA1MzQ2RDM4ODVGRTk4AA==",
  "whatsapp_id": "wamid.HBgNNTUyMTk5NjMyMjE5NRUCABIYIEJBOTVGQjE5NTYwNkI5NDYzNDA1MzQ2RDM4ODVGRTk4AA==",
  "whatsapp_api_key": "EAAGIBII4GXQBO2qgvJ2jdcUmgkdqBo5bUKEanJWmCLpcZAsq0Ovpm4JNlrNLeZAv3OYNrdCqqQBAHfEfPFD0FPnZAOQJURB9GKcbjXeDpa83XdAsa3i6fTr23lBFM2LwUZC23xXrZAnB8QjCCFZBxrxlBvzPj8LsejvUjz0C04Q8Jsl8nTGHUd4ZBRPc4NiHFnc"
}
```

### Depois (organizado e com novos campos):
```json
{
  "wamid": "wamid.HBgNNTUyMTk5NjMyMjE5NRUCABIYIEJBOTVGQjE5NTYwNkI5NDYzNDA1MzQ2RDM4ODVGRTk4AA==",
  "whatsapp_api_key": "EAAGIBII4GXQBO2qgvJ2jdcUmgkdqBo5bUKEanJWmCLpcZAsq0Ovpm4JNlrNLeZAv3OYNrdCqqQBAHfEfPFD0FPnZAOQJURB9GKcbjXeDpa83XdAsa3i6fTr23lBFM2LwUZC23xXrZAnB8QjCCFZBxrxlBvzPj8LsejvUjz0C04Q8Jsl8nTGHUd4ZBRPc4NiHFnc",
  "phone_number_id": "123456789",
  "business_id": "987654321"
}
```

## Origem dos Dados

Os novos campos são extraídos do `provider_config` do canal WhatsApp:
- `phone_number_id`: `inbox.channel.provider_config['phone_number_id']`
- `business_id`: `inbox.channel.provider_config['business_account_id']`

Esses valores são configurados quando o usuário cria um canal WhatsApp no frontend, conforme mostrado na imagem fornecida:
- **ID do número de telefone**: Campo obrigatório obtido do painel do Facebook Developer
- **ID da conta do WhatsApp Business**: Campo obrigatório obtido do painel do Facebook Developer

## Compatibilidade

As mudanças mantêm total compatibilidade com integrações existentes:
1. Todos os campos existentes continuam presentes
2. Apenas removida a duplicação desnecessária
3. Novos campos são opcionais (podem ser `nil`)
4. Estrutura flat do payload mantida para Dialogflow
5. Fallback gracioso em caso de erro

## Validação

O serviço inclui validação completa dos novos campos:
- Verificação de tipos de dados (string ou nil)
- Logs detalhados para debugging
- Tratamento de erros gracioso
- Estrutura de fallback em caso de falha

## Resultado

O payload agora está organizado, sem duplicações, e inclui as informações essenciais do WhatsApp Business API (`phone_number_id` e `business_id`) necessárias para integrações avançadas com o Flowise e outros sistemas.