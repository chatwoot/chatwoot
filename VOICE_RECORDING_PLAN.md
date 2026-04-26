# Plano de Implementação: Gravação e Sincronização de Áudio (Voz)

Este documento detalha as etapas necessárias para habilitar a gravação de chamadas via Twilio e garantir que o áudio seja sincronizado e anexado à conversa no Chatwoot.

## 1. Habilitação da Gravação (Concluído ✅)
As seguintes alterações foram feitas no `enterprise/app/services/voice/provider/twilio/adapter.rb`:
- Adicionado `record: true` nos parâmetros de criação da chamada.
- Definido `recording_status_callback` para apontar para a nova rota de processamento.
- Implementado o método auxiliar `twilio_recording_status_url`.

## 2. Rota de Callback (Concluído ✅)
- Adicionada a rota `POST /twilio/voice/recording_status/:phone` no arquivo `config/routes.rb`.

## 3. Implementação do Controller (Concluído ✅)
Adicionada a ação `recording_status` no `Twilio::VoiceController`:
- **Local**: `enterprise/app/controllers/twilio/voice_controller.rb`
- **Responsabilidade**: Receber o `RecordingUrl` e o `CallSid` do Twilio e disparar o Job de sincronização.

## 4. Job de Sincronização (Concluído ✅)
Criado o Job `Voice::RecordingSyncJob`:
- **Local**: `enterprise/app/jobs/voice/recording_sync_job.rb`
- **Responsabilidade**:
  1. Baixar o áudio do Twilio via `Down.download`.
  2. Localizar a `Message` do tipo `voice_call` que possui o `CallSid` correspondente nos `content_attributes`.
  3. Anexar o arquivo MP3 à mensagem via `ActiveStorage`.
  4. O Chatwoot enviará automaticamente o arquivo para o S3 (`prod-chat`) conforme configurado.

## 5. Interface (Opcional/Pendente ⏳)
- Garantir que o player de áudio seja exibido corretamente na bolha de mensagem do tipo `voice_call` no dashboard.

---
**Branch**: `feat/voice-recording-sync`
