# WhatsApp SocialWise Flow Rich Message Fix

## Problema Identificado

O WhatsApp estava apresentando um "flash effect" onde as mensagens ricas apareciam e depois sumiam no dashboard. Isso acontecia porque:

1. A mensagem era criada inicialmente como texto simples
2. Depois era atualizada para rich content pelo `Whatsapp::RichMessageService`
3. Essa atualização causava o efeito de "flash" na interface

## Solução Implementada

Seguindo o padrão bem-sucedido do Instagram, implementamos uma solução modular e robusta:

### 1. Novo Processador Dedicado (`WhatsappResponseProcessor`)

**Arquivo:** `lib/integrations/socialwise_flow/whatsapp_response_processor.rb`

- Processador específico para WhatsApp seguindo o padrão do Instagram
- Cria mensagens diretamente como rich content (evita flash effect)
- Usa `Messages::WhatsappRendererMapper` para conversão de payload
- Implementa fallbacks robustos para cenários de erro

### 2. Atualização do Processador Principal

**Arquivo:** `lib/integrations/socialwise_flow/processor_service.rb`

- Delegação para o novo `WhatsappResponseProcessor`
- Validação de canal WhatsApp
- Método de fallback específico para WhatsApp
- Logs detalhados para debugging

### 3. Melhorias no RichMessageService

**Arquivo:** `app/services/whatsapp/rich_message_service.rb`

- Detecção de mensagens criadas pelo SocialWise Flow
- Evita processamento duplo (causa do flash effect)
- Suporte para `content_type: 'integrations'`
- Flag `socialwise_flow_message` para identificação

## Arquivos Modificados

1. **Novo:** `lib/integrations/socialwise_flow/whatsapp_response_processor.rb`
2. **Modificado:** `lib/integrations/socialwise_flow/processor_service.rb`
3. **Modificado:** `app/services/whatsapp/rich_message_service.rb`

## Arquivos de Teste

1. **Novo:** `test_whatsapp_fix.rb` - Teste de validação da correção
2. **Novo:** `test-whatsapp-fix.ps1` - Script Docker para testes
3. **Novo:** `docker-compose.test.yml` - Configuração Docker para testes

## Como Testar

### Opção 1: Teste Rápido com Docker
```powershell
./test-whatsapp-fix.ps1
```

### Opção 2: Teste Manual com Docker
```powershell
# Construir imagem de teste
docker-compose -f docker-compose.test.yml build test

# Iniciar dependências
docker-compose -f docker-compose.test.yml up -d postgres_test redis_test

# Executar teste
docker-compose -f docker-compose.test.yml run --rm test ruby test_whatsapp_fix.rb

# Limpar
docker-compose -f docker-compose.test.yml down
```

### Opção 3: Teste Completo
```powershell
./test-docker.ps1 socialwise
```

## Fluxo da Correção

### Antes (Problema)
1. SocialWise Flow envia payload WhatsApp
2. `ProcessorService` cria mensagem como texto simples
3. `Whatsapp::RichMessageService` atualiza mensagem para rich content
4. **Flash effect:** mensagem aparece como texto, depois como rich, depois some

### Depois (Correção)
1. SocialWise Flow envia payload WhatsApp
2. `ProcessorService` delega para `WhatsappResponseProcessor`
3. `WhatsappResponseProcessor` usa `WhatsappRendererMapper`
4. Mensagem é criada **diretamente** como rich content
5. Flag `skip_send_reply: true` evita envio duplo
6. Flag `socialwise_flow_message: true` evita processamento duplo
7. **Sem flash effect:** mensagem aparece corretamente desde o início

## Benefícios da Solução

1. **Modularidade:** Processador dedicado para WhatsApp
2. **Consistência:** Segue o padrão bem-sucedido do Instagram
3. **Robustez:** Fallbacks para cenários de erro
4. **Performance:** Evita processamento duplo
5. **UX:** Elimina o flash effect
6. **Manutenibilidade:** Código organizado e bem documentado

## Flags Importantes

- `skip_send_reply: true` - Evita envio duplo da mensagem
- `socialwise_flow_message: true` - Identifica mensagens do SocialWise Flow
- `content_type: 'integrations'` - Tipo correto para mensagens ricas

## Logs para Debugging

Todos os logs usam o prefixo `[SOCIALWISE-FLOW-WHATSAPP]` para fácil identificação:

```ruby
Rails.logger.info "[SOCIALWISE-FLOW-WHATSAPP] Creating rich message directly (Instagram pattern)"
Rails.logger.info "[SOCIALWISE-FLOW-WHATSAPP] Message created directly with ID: #{message.id}"
```

## Compatibilidade

- ✅ WhatsApp Cloud API
- ✅ WhatsApp 360Dialog (UnoAPI)
- ✅ Mensagens interativas (buttons, lists)
- ✅ Mensagens de texto simples
- ✅ Fallbacks para cenários de erro

## Próximos Passos

1. Executar testes para validar a correção
2. Testar em ambiente de desenvolvimento
3. Monitorar logs para confirmar funcionamento
4. Deploy em produção
5. Validar com usuários finais

A solução foi projetada para ser robusta, seguir padrões estabelecidos e resolver definitivamente o problema do flash effect no WhatsApp.