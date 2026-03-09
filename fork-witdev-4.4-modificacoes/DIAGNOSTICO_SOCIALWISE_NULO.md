# Diagnóstico: Dados Socialwise Nulos

## Análise dos Logs

### Logs Recebidos:
```
Started POST "/webhooks/whatsapp/+558592091821" for 173.252.95.112
Processing by Webhooks::WhatsappController#process_payload
Parameters: {
  "phone_number_id" => "274633962398273",
  "contacts" => [{"profile" => {"name" => "Witalo Rocha"}, "wa_id" => "558597550136"}],
  "messages" => [{
    "from" => "558597550136",
    "id" => "wamid.HBgMNTU4NTk3NTUwMTM2FQIAEhgUM0FCODMwRTE2NzZENjUxQTM2QjAA",
    "type" => "image"
  }]
}
```

### Observações:
1. ✅ **Webhook recebido corretamente** do WhatsApp
2. ✅ **Job enfileirado** no Sidekiq
3. ❌ **Nenhum log do Socialwise** aparece
4. ❌ **Dados chegam nulos** no webhook final

## Possíveis Causas

### 1. **Socialwise Não Ativo** (Mais Provável)
```ruby
# O hook não existe ou não está habilitado
hook = account.hooks.find_by(app_id: 'socialwise_chatwit', status: 'enabled')
# => nil
```

### 2. **Webhook Enhancement Desabilitado**
```ruby
# A configuração está desabilitada
hook.settings['webhook_enhancement_enabled'] # => false
```

### 3. **Inbox Não Encontrada**
```ruby
# O número do webhook não corresponde a nenhuma inbox
Inbox.joins(:channel).where(
  channel_type: 'Channel::Whatsapp',
  channels: { phone_number: '+558592091821' }
).first # => nil
```

### 4. **Provider Config Ausente**
```ruby
# A inbox existe mas não tem provider_config
inbox.channel.provider_config # => {}
```

## Scripts de Diagnóstico Criados

### 1. **Verificação Completa**
```bash
ruby debug_socialwise_logs.rb
```
- Analisa o payload do webhook
- Verifica se a inbox existe
- Testa configurações do Socialwise
- Identifica a causa raiz

### 2. **Verificação Rápida**
```bash
ruby check_socialwise_status.rb
```
- Lista status de todas as contas
- Mostra configurações do Socialwise
- Conta inboxes WhatsApp

### 3. **Ativação Automática**
```bash
ruby activate_socialwise.rb
```
- Ativa o Socialwise para todas as contas
- Configura webhook enhancement
- Verifica resultado final

## Logs Adicionados para Debug

### No WebhookListener:
```ruby
Rails.logger.info "[WEBHOOK] Calling Socialwise enhancement for account #{account.id}"
Rails.logger.info "[WEBHOOK] Socialwise enhancement result: #{original_keys} -> #{enhanced_keys} keys"
Rails.logger.info "[WEBHOOK] Socialwise data present: #{final_payload.key?('socialwise-chatwit')}"
```

### No SocialwiseService:
```ruby
Rails.logger.info "[SOCIALWISE] enhance_payload called for account #{account&.id}"
Rails.logger.info "[SOCIALWISE] Socialwise not active for account #{account&.id}, skipping enhancement"
Rails.logger.info "[SOCIALWISE] Webhook enhancement disabled for account #{account&.id}, skipping enhancement"
```

## Solução Mais Provável

### Problema:
O **Socialwise não está ativo** para a conta que está recebendo os webhooks.

### Solução:
1. **Verificar status atual**:
   ```bash
   ruby check_socialwise_status.rb
   ```

2. **Ativar se necessário**:
   ```bash
   ruby activate_socialwise.rb
   ```

3. **Ou ativar manualmente**:
   - Acesse o dashboard de integrações
   - Encontre "Socialwise Chatwit"
   - Marque "Ativar Socialwise Chatwit"
   - Marque "Ativar Enhancement de Webhooks"
   - Salve as configurações

4. **Testar novamente**:
   - Envie uma mensagem no WhatsApp
   - Verifique os logs para ver:
     ```
     [SOCIALWISE] enhance_payload called for account 3
     [SOCIALWISE] Starting payload enhancement for account 3
     [WEBHOOK] Socialwise enhancement result: 15 -> 45 keys
     [WEBHOOK] Socialwise data present: true
     ```

## Verificação Final

Após ativar o Socialwise, os logs devem mostrar:

### Logs Esperados:
```
[WEBHOOK] Calling Socialwise enhancement for account 3
[SOCIALWISE] enhance_payload called for account 3
[SOCIALWISE] Checking if socialwise is active for account 3
[SOCIALWISE] Hook found with enabled=true, active=true
[SOCIALWISE] Checking webhook enhancement for account 3
[SOCIALWISE] webhook_enhancement_enabled=true, enabled=true
[SOCIALWISE] Starting payload enhancement for account 3
[SOCIALWISE] Building socialwise-chatwit data for account 3
[SOCIALWISE] Extracted objects - Message: OpenStruct, Conversation: OpenStruct, Contact: OpenStruct, Inbox: OpenStruct
[SOCIALWISE] Cached provider_config for inbox 4
[SOCIALWISE] Successfully built socialwise-chatwit data
[SOCIALWISE] Flat webhook payload enhanced with 35 total fields
[WEBHOOK] Socialwise enhancement result: 15 -> 35 keys
[WEBHOOK] Socialwise data present: true
```

### Payload Final Esperado:
```json
{
  "event": "message_created",
  "wamid": "wamid.HBgMNTU4NTk3NTUwMTM2FQIAEhgUM0FCODMwRTE2NzZENjUxQTM2QjAA",
  "contact_name": "Witalo Rocha",
  "contact_phone": "+558597550136",
  "whatsapp_api_key": "EAAGIBII4GXQBO...",
  "phone_number_id": "274633962398273",
  "business_id": "294585820394901",
  "socialwise-chatwit": { /* dados completos */ }
}
```

## Conclusão

A causa mais provável dos **dados nulos** é que o **Socialwise não está ativo** para a conta. Execute os scripts de diagnóstico para confirmar e ativar se necessário.

Uma vez ativo, os logs detalhados mostrarão exatamente o que está acontecendo em cada etapa do processo.