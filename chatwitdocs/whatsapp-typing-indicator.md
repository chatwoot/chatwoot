# WhatsApp Typing Indicator (Mark as Read + Digitando)

> **Versao**: 1.0.0
> **Data**: 19 de Fevereiro de 2026
> **Objetivo**: Enviar feedback visual "Digitando..." para usuarios do WhatsApp quando bot ou agente humano esta processando/escrevendo resposta.

---

## Visao Geral

O sistema de typing indicator melhora a experiencia do usuario no WhatsApp mostrando:
1. **Marcacao de leitura** (tick azul duplo)
2. **Indicador "Digitando..."** na conversa

Isso funciona em dois cenarios:
- **Bot (SocialWise Flow)**: Quando uma mensagem e recebida e o bot esta processando
- **Agente Humano**: Quando um agente comeca a digitar uma resposta no dashboard

---

## API WhatsApp Utilizada

Endpoint: `POST https://graph.facebook.com/{version}/{phone_number_id}/messages`

Payload:
```json
{
  "messaging_product": "whatsapp",
  "status": "read",
  "message_id": "<WHATSAPP_MESSAGE_ID>",
  "typing_indicator": {
    "type": "text"
  }
}
```

**Comportamento:**
- Marca a mensagem como lida (tick azul)
- Mostra indicador "Digitando..." por ate 25 segundos
- Indicador e removido automaticamente quando mensagem e enviada ou apos 25s

---

## Fluxo 1: Bot (SocialWise Flow)

### Quando e Acionado
- **IMEDIATAMENTE** ao receber mensagem de texto ou interativa (botao/lista)
- **ANTES** do debounce - o usuario ve "Digitando..." instantaneamente
- Funciona com debounce habilitado ou desabilitado

### Arquivos Envolvidos
- `lib/integrations/socialwise_flow/processor_service.rb` - metodo `send_typing_indicator_to_user` chamado no inicio de `perform`
- `app/services/whatsapp/providers/whatsapp_cloud_service.rb` - metodo `mark_read_with_typing`

### Fluxo de Execucao
```
Webhook WP recebido
    -> IncomingMessageWhatsappCloudService.perform
    -> create_messages (Message criado com source_id = wamid.xxx)
    -> SocialwiseFlow::ProcessorService.perform
    -> send_typing_indicator_to_user(message)  <- IMEDIATO (antes do debounce!)
    -> Usuario ve: tick azul + "Digitando..."
    -> [se debounce ativo: enqueue_for_debounce e aguarda silencio]
    -> get_response (webhook SocialWise)
    -> Resposta enviada (typing removido)
```

---

## Fluxo 2: Agente Humano

### Quando e Acionado
- Quando agente comeca a digitar no ReplyBox do dashboard
- Frontend envia evento `typing_on` via API
- Sistema detecta que e conversa WhatsApp Cloud e envia para API

### Arquivos Envolvidos
- `app/listeners/whatsapp_typing_listener.rb` - listener para evento typing_on
- `app/jobs/whatsapp_typing_job.rb` - job assincrono para enviar typing
- `app/dispatchers/sync_dispatcher.rb` - registra o listener

### Fluxo de Execucao
```
Agente digita no dashboard
    -> ReplyBox.vue @keyup
    -> toggleTyping('on')
    -> API POST /toggle_typing_status
    -> TypingStatusManager.trigger_typing_event(CONVERSATION_TYPING_ON)
    -> SyncDispatcher.dispatch
    -> WhatsappTypingListener.conversation_typing_on(event)
    -> WhatsappTypingJob.perform_later(conversation_id, user_id)
    -> Busca ultima mensagem incoming (source_id = wamid.xxx)
    -> mark_read_with_typing(last_incoming.source_id)
    -> Usuario ve: tick azul + "Digitando..."
```

### Condicoes para Envio
- Usuario e agente (nao Contact)
- Inbox e Channel::Whatsapp com provider `whatsapp_cloud`
- Nao e nota privada (is_private = false)

---

## Logs para Debug

### Sucesso
```
[WhatsappCloudService] Mark read + typing sent for wamid.xxx
[SOCIALWISE-FLOW] Mark read + typing sent for wamid.xxx
```

### Falha (nao-bloqueante)
```
[WhatsappCloudService] Mark read + typing failed: 400 - {...}
[WhatsappCloudService] Mark read + typing error (non-blocking): Connection refused
```

---

## Configuracao

**Nenhuma variavel de ambiente necessaria** - feature sempre ativa para conversas WhatsApp Cloud.

Variaveis relacionadas (ja existentes):
- `WHATSAPP_CLOUD_BASE_URL` - URL base da API (default: `https://graph.facebook.com`)

---

## Testes

```bash
# Entrar no container
./dev.sh shell

# Rodar testes do WhatsApp Cloud Service
bundle exec rspec spec/services/whatsapp/providers/whatsapp_cloud_service_spec.rb -e "mark_read_with_typing"
```

---

## Consideracoes

1. **Rate Limiting**: WhatsApp nao documenta rate limits especificos para typing, mas o indicador dura 25s. O debounce do frontend (4s) evita spam.

2. **Non-blocking**: Falhas na API nao bloqueiam o fluxo principal. Erros sao logados mas nao raised.

3. **Apenas WhatsApp Cloud**: Feature nao afeta outros providers (360Dialog, etc).

4. **Debounce Frontend**: O ReplyBox.vue ja tem debounce de 4 segundos para eventos typing_on, evitando multiplas chamadas rapidas.
