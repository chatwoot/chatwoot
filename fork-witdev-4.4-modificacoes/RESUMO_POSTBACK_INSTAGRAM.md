# Resumo: Implementação de Suporte a Postbacks no Instagram

## Problema Identificado
O usuário relatou que após modificações no fluxo do Instagram para receber e renderizar rich messages, os postbacks de botões não estavam mais aparecendo no chat. Quando um usuário clicava em um botão, o Chatwoot não exibia o texto do postback na conversa.

## Solução Implementada

### 1. Criação do Parser do Instagram
**Arquivo:** `lib/integrations/instagram/message_parser.rb`
- Criado parser específico para Instagram baseado no parser do Facebook
- Implementados métodos para detectar e extrair dados de postbacks e quick replies:
  - `postback?` - detecta se é um evento de postback
  - `postback_title` - extrai o título do botão
  - `postback_payload` - extrai o payload do botão
  - `quick_reply?` - detecta se é um quick reply
  - `quick_reply_payload` - extrai o payload do quick reply

### 2. Modificação do Job de Eventos do Instagram
**Arquivo:** `app/jobs/webhooks/instagram_events_job.rb`
- Adicionado `:postback` aos eventos suportados (`SUPPORTED_EVENTS`)
- Implementado método `postback` para processar eventos de postback
- Postbacks são tratados da mesma forma que mensagens regulares

### 3. Atualização do Message Builder do Instagram
**Arquivo:** `app/builders/messages/instagram/base_message_builder.rb`
- Modificado `message_content` para usar o parser e extrair conteúdo correto:
  - Para postbacks: usa `postback_title` ou `postback_payload`
  - Para quick replies: usa o texto da mensagem
  - Para mensagens regulares: usa o texto normal
- Atualizado `message_params` para incluir payloads nos `content_attributes`:
  - `postback_payload` para postbacks
  - `quick_reply_payload` para quick replies

### 4. Melhorias no Parser do Facebook
**Arquivo:** `lib/integrations/facebook/message_parser.rb`
- Adicionados métodos para postbacks e quick replies (compatibilidade)
- Corrigidos métodos existentes para evitar erros com valores nil

### 5. Atualização do Message Builder do Facebook
**Arquivo:** `app/builders/messages/facebook/message_builder.rb`
- Implementado `message_content` para extrair conteúdo correto de postbacks
- Atualizado `message_params` para incluir payloads nos `content_attributes`

### 6. Integração com Dialogflow
**Arquivo:** `lib/integrations/dialogflow/processor_service.rb`
- Adicionado suporte para dados do Instagram no payload enviado ao Dialogflow
- Incluídos campos `postback_payload` e `quick_reply_payload` no payload flat

### 7. Integração com SocialWise
**Arquivo:** `lib/integrations/socialwise/webhook_enhancer_service.rb`
- Adicionado método `extract_instagram_data_from_message` para extrair dados do Instagram
- Incluídos dados do Instagram no payload estruturado do SocialWise
- Adicionados campos do Instagram no payload flat para compatibilidade

## Fluxo Completo Implementado

### Para Postbacks:
1. **Webhook recebido** → `InstagramEventsJob` identifica evento `postback`
2. **Parser extrai dados** → `postback_title`, `postback_payload`
3. **Mensagem criada** → conteúdo = título do botão, payload salvo em `content_attributes`
4. **Exibição no chat** → usuário vê o texto do botão que clicou
5. **Integração Dialogflow** → payload enviado para automações

### Para Quick Replies:
1. **Webhook recebido** → `InstagramEventsJob` identifica `message` com `quick_reply`
2. **Parser extrai dados** → `quick_reply_payload`, texto da mensagem
3. **Mensagem criada** → conteúdo = texto da resposta, payload salvo em `content_attributes`
4. **Exibição no chat** → usuário vê o texto da opção escolhida
5. **Integração Dialogflow** → payload enviado para automações

## Testes Realizados
- ✅ Parser do Instagram funciona corretamente para postbacks, quick replies e mensagens regulares
- ✅ Eventos suportados incluem `:postback`
- ✅ Extração de conteúdo funciona para todos os tipos de mensagem
- ✅ Integração com Dialogflow preservada
- ✅ Compatibilidade com SocialWise mantida

## Arquivos Modificados
1. `lib/integrations/instagram/message_parser.rb` (novo)
2. `app/jobs/webhooks/instagram_events_job.rb`
3. `app/builders/messages/instagram/base_message_builder.rb`
4. `lib/integrations/facebook/message_parser.rb`
5. `app/builders/messages/facebook/message_builder.rb`
6. `lib/integrations/dialogflow/processor_service.rb`
7. `lib/integrations/socialwise/webhook_enhancer_service.rb`

## Resultado
✅ **Problema resolvido**: Postbacks do Instagram agora aparecem corretamente no chat
✅ **Texto exibido**: Quando usuário clica em botão, o texto do botão aparece na conversa
✅ **Payload preservado**: Payload do botão é salvo para automações
✅ **Compatibilidade**: Funciona com Dialogflow e outras integrações
✅ **Extensibilidade**: Suporte também adicionado para quick replies