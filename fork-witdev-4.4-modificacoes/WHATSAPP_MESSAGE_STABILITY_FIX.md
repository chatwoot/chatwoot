# Correção da Estabilidade das Mensagens Ricas do WhatsApp

## Problema Identificado

Baseado na sua análise perfeita, o problema era que as mensagens ricas do WhatsApp apareciam momentaneamente e depois "sumiam". Isso acontecia devido a **atualizações desnecessárias** após a criação da mensagem.

## Causa Raiz

1. **Mensagem criada** pelo SocialWise Flow com `content_type: 'integrations'`
2. **RichMessageService executado** para enviar a mensagem
3. **RichMessageService modifica** `content_attributes` adicionando `interactive_payload`
4. **message.save!** dispara `after_update_commit` → `MESSAGE_UPDATED` event
5. **Front-end recebe evento** e pode causar problemas na renderização
6. **Mensagem "some"** ou fica instável

## Solução Implementada

### 1. Prevenção de Atualizações Desnecessárias

**No SocialWise Flow (`processor_service.rb`):**
- Incluir `interactive_payload` já na criação da mensagem
- Adicionar flags de proteção: `preserve_content`, `socialwise_flow_message`

```ruby
content_attributes: {
  'interactive' => whatsapp_payload['interactive'],
  'type' => whatsapp_payload['type'],
  'whatsapp_interactive_payload' => whatsapp_payload['interactive'],
  'interactive_payload' => whatsapp_payload['interactive']  # ← NOVO: evita atualização
}

additional_attributes: {
  'skip_send_reply' => true,
  'socialwise_flow_message' => true,
  'preserve_content' => true  # ← NOVO: flag de proteção
}
```

### 2. Otimização do RichMessageService

**No `app/services/whatsapp/rich_message_service.rb`:**
- Verificar se `interactive_payload` já existe antes de salvar
- Evitar `message.save!` desnecessário

```ruby
# Antes
message.content_attributes['interactive_payload'] = interactive_payload
message.save!

# Depois
unless message.content_attributes['interactive_payload'] == interactive_payload
  message.content_attributes['interactive_payload'] = interactive_payload
  message.save!
  Rails.logger.info "[SOCIALWISE-WHATSAPP-RICH] Interactive payload stored in message"
else
  Rails.logger.info "[SOCIALWISE-WHATSAPP-RICH] Interactive payload already present, skipping save"
end
```

### 3. Atualização Segura do source_id

**Usar `update_column` ao invés de `update!`:**
```ruby
# Antes
outgoing_message.update!(source_id: message_id)

# Depois  
outgoing_message.update_column(:source_id, message_id)  # Não dispara callbacks
```

## Resultado Esperado

### Antes da Correção
- ❌ Mensagem aparece momentaneamente
- ❌ RichMessageService causa atualização desnecessária
- ❌ Evento MESSAGE_UPDATED confunde o front-end
- ❌ Mensagem "some" ou fica instável

### Depois da Correção
- ✅ Mensagem criada com todos os dados necessários
- ✅ RichMessageService não causa atualizações desnecessárias
- ✅ Apenas uma atualização mínima para source_id
- ✅ Mensagem permanece estável e visível

## Como Testar

### 1. Teste de Estabilidade
```bash
rails runner test_message_stability.rb
```

### 2. Monitoramento de Logs
```bash
tail -f log/development.log | grep "SOCIALWISE-FLOW\|SOCIALWISE-WHATSAPP-RICH"
```

### 3. Verificação Manual
1. Envie uma mensagem rica do SocialWise Flow
2. Verifique se ela aparece no dashboard
3. Confirme que ela **não some** após alguns segundos
4. Verifique se os botões estão funcionais

## Logs de Sucesso

Procure por estes logs para confirmar que está funcionando:

```
[SOCIALWISE-FLOW][WHATSAPP] Message created successfully: 12345 (content_type: integrations)
[SOCIALWISE-FLOW][WHATSAPP] SocialWise Flow flag: true
[SOCIALWISE-WHATSAPP-RICH] Interactive payload already present, skipping save
[SOCIALWISE-FLOW][WHATSAPP] Interactive message sent successfully, source_id: wamid.xxx
[SOCIALWISE-FLOW][WHATSAPP] Message preserved with content_type: integrations
```

## Arquivos Modificados

1. **`lib/integrations/socialwise_flow/processor_service.rb`**
   - Incluir `interactive_payload` na criação
   - Adicionar flags de proteção
   - Usar `update_column` para source_id

2. **`app/services/whatsapp/rich_message_service.rb`**
   - Verificar payload existente antes de salvar
   - Evitar atualizações desnecessárias

## Compatibilidade

- ✅ Mantém total compatibilidade com mensagens existentes
- ✅ Não afeta outros canais (Instagram, Facebook, etc.)
- ✅ Preserva funcionalidade de envio para WhatsApp
- ✅ Melhora performance (menos atualizações desnecessárias)

## Monitoramento Contínuo

Para garantir que o problema não retorne:

1. **Verificar mensagens que "somem"**: Se mensagens ainda estão sumindo, verificar logs de erro
2. **Monitorar atualizações**: Mensagens não devem ser atualizadas múltiplas vezes
3. **Validar flags**: Todas as mensagens do SocialWise Flow devem ter os flags de proteção
4. **Performance**: Menos eventos MESSAGE_UPDATED = melhor performance

Esta solução mantém as mensagens **exatamente como você viu na imagem** - com imagem, texto e botões visíveis - e garante que elas **não sumam mais**.